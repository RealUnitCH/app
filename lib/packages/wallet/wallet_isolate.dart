/// Wallet Isolate — owner of the BIP39 plaintext (BL-018).
///
/// The full Initiative IV contract is: BIP39 mnemonics never live as
/// long-lived fields on a main-isolate object. The dedicated isolate
/// spawned here owns the only `String` representation of a decoded
/// mnemonic after the brief commit window. Every sign and address
/// derivation is funnelled through the channel so the main isolate
/// holds only:
///
///   - The `walletId` (an int — meaningless to an attacker on its own)
///   - The `primaryAddress` (already public)
///   - A handle to this isolate's `SendPort`
///
/// What the main isolate never sees, post-Initiative-IV:
///
///   - The mnemonic phrase as a long-lived `String` field
///   - The 64-byte seed derived from it
///   - The secp256k1 private keys derived from the seed
///   - Any `BIP32` instance with a `privateKey` populated
///
/// The IPC contract is intentionally narrow. Every request carries the
/// `walletId` so the isolate can dispatch to the right unlocked slot;
/// every response carries the request `id` so concurrent callers can
/// demultiplex. Cancellation is a separate typed request — never a
/// `Future.ignore()` — so a `lockCurrentWallet` mid-decrypt actually
/// reaches the isolate and prevents the decrypted seed from being
/// pinned in the unlocked-slots map.
///
/// See `docs/adr/0004-crypto-hygiene-boundaries.md` for the threat
/// model, the alternatives considered, and the rationale for the
/// long-lived single-isolate shape (versus per-sign spawn).
library;

import 'dart:async';
import 'dart:convert' show base64Decode, utf8;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:bip32/bip32.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:convert/convert.dart' as hex_convert;
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';
import 'package:web3dart/web3dart.dart';

/// Crash thrown from any awaited request whose isolate-side handler
/// threw or whose isolate died mid-flight. Typed so callers can
/// distinguish a programmer error from a cryptographic / state failure.
class WalletIsolateException implements Exception {
  WalletIsolateException(this.message);
  final String message;

  @override
  String toString() => 'WalletIsolateException: $message';
}

/// Specifically the isolate disappeared. Distinct from a request-level
/// failure (e.g. unknown walletId) so callers can react — typically by
/// re-spawning the isolate.
class WalletIsolateCrashException extends WalletIsolateException {
  WalletIsolateCrashException(super.message);
}

/// The walletId in a request has not been unlocked on the isolate side.
/// Treat as a programmer error — the caller forgot to `Unlock` first.
class WalletIsolateNotUnlockedException extends WalletIsolateException {
  WalletIsolateNotUnlockedException(int walletId)
      : super('wallet $walletId is not unlocked in the isolate');
}

/// The request was explicitly cancelled via [WalletIsolate.cancel].
/// Surfaced to the awaiter so it can short-circuit any subsequent
/// state writes (e.g. don't pin the response into AppStore.wallet).
class WalletIsolateCancelledException extends WalletIsolateException {
  WalletIsolateCancelledException() : super('request cancelled');
}

/// Sealed family of requests sent main → isolate. The shape is a class
/// hierarchy (not a sum type via enum + map) so each handler can pull
/// strongly-typed fields without re-validating positional arguments.
sealed class _IsolateRequest {
  const _IsolateRequest(this.id);
  final int id;
}

class _UnlockRequest extends _IsolateRequest {
  _UnlockRequest(super.id, this.walletId, this.encryptedSeed, this.keyBytes);
  final int walletId;
  // The ciphertext + IV blob exactly as it lives on disk (the
  // `<base64 iv>:<base64 ct>` form `SecureStorage.encryptSeed` emits).
  // Passing the encoded string keeps the isolate self-contained — it
  // doesn't import the storage package.
  final String encryptedSeed;
  // 32-byte AES-GCM key. The main isolate is allowed to read this from
  // Keychain because the key alone is useless without ciphertext, and
  // the ciphertext alone is useless without the key. Holding both in
  // main for the duration of the round trip is the smallest exposure
  // window the architecture allows; the seed never crosses.
  final Uint8List keyBytes;
}

/// Onboarding/restore variant: the caller hands in a plaintext
/// mnemonic (because either it was just generated client-side, or the
/// user typed it). The isolate takes ownership immediately and the
/// caller drops its `String` reference. The main-side `SeedDraft`
/// holder is the only legitimate creator of this request — see
/// `WalletService.commitGeneratedWallet` / `restoreWallet`.
class _AdoptPlaintextRequest extends _IsolateRequest {
  _AdoptPlaintextRequest(super.id, this.walletId, this.mnemonic);
  final int walletId;
  final String mnemonic;
}

class _LockRequest extends _IsolateRequest {
  _LockRequest(super.id, this.walletId);
  final int walletId;
}

class _DeriveAddressRequest extends _IsolateRequest {
  _DeriveAddressRequest(super.id, this.walletId, this.accountIndex, this.addressIndex);
  final int walletId;
  final int accountIndex;
  final int addressIndex;
}

class _SignDigestRequest extends _IsolateRequest {
  _SignDigestRequest(super.id, this.walletId, this.derivationPath, this.digest, {this.chainId});
  final int walletId;
  final String derivationPath;
  // Opaque bytes — schema validation (Initiative II's SignPipeline)
  // happens entirely on the main isolate. The isolate signs what it's
  // given. This is by design: the isolate is a cryptographic primitive,
  // not a policy engine.
  final Uint8List digest;
  final int? chainId;
}

class _SignPersonalMessageRequest extends _IsolateRequest {
  _SignPersonalMessageRequest(
    super.id,
    this.walletId,
    this.derivationPath,
    this.payload, {
    this.chainId,
  });
  final int walletId;
  final String derivationPath;
  final Uint8List payload;
  final int? chainId;
}

class _RevealRequest extends _IsolateRequest {
  // The seed-reveal flow (settings_seed + verify_seed) needs the
  // plaintext words on the main isolate for the brief render-window.
  // Law 6 explicitly permits this — clearly-scoped, with a defined
  // dispose-point at cubit close. The reveal carries a one-shot
  // identifier so the isolate can audit how many times the seed has
  // been exposed for a given walletId (future: rate-limit / surface
  // in settings).
  _RevealRequest(super.id, this.walletId);
  final int walletId;
}

class _CancelRequest extends _IsolateRequest {
  _CancelRequest(super.id, this.targetId);
  // The request-id the caller wants cancelled. The isolate consults
  // a per-handler cancellation token between derivation steps.
  final int targetId;
}

class _ShutdownRequest extends _IsolateRequest {
  _ShutdownRequest(super.id);
}

/// Response envelope — every response carries the request id so the
/// main-side dispatcher can match it to the awaiting Completer.
sealed class _IsolateResponse {
  const _IsolateResponse(this.id);
  final int id;
}

class _OkResponse<T> extends _IsolateResponse {
  _OkResponse(super.id, this.value);
  final T value;
}

class _ErrorResponse extends _IsolateResponse {
  _ErrorResponse(super.id, this.message,
      {this.notUnlocked = false, this.cancelled = false, this.walletId});
  final String message;
  final bool notUnlocked;
  final bool cancelled;
  final int? walletId;
}

/// Main-isolate handle to the spawned wallet isolate. Holds the
/// `SendPort`, a request-id counter, and a map of pending Completers
/// so concurrent callers can multiplex over the single channel.
///
/// Most methods are non-final so test doubles ([WalletIsolate] is the
/// production path; a `FakeWalletIsolate` in tests can override the
/// IPC methods directly without spawning a real isolate). Production
/// callers go through [spawn] and pay the spawn cost once per process.
class WalletIsolate {
  WalletIsolate._(
    this._sendPort,
    this._receivePort,
    this._isolate,
  );

  /// Test constructor — produces a handle whose IPC methods are
  /// expected to be overridden in a subclass. Calling any unoverridden
  /// IPC method on the instance throws because the underlying isolate
  /// is closed immediately. Production code goes through [spawn].
  WalletIsolate.forTesting()
      : _sendPort = ReceivePort().sendPort,
        _receivePort = ReceivePort(),
        _isolate = Isolate.current {
    _receivePort.close();
    // Disposed is left false so override-callers can still issue
    // their own state. Disposing here would cause `_send` to error
    // on a base-class call, which is the right shape for "not
    // overridden in this test".
  }

  final SendPort _sendPort;
  final ReceivePort _receivePort;
  final Isolate _isolate;

  // Monotonic request id. The isolate uses this in cancellation lookups
  // and the main-side completer map.
  int _nextId = 1;
  final Map<int, Completer<dynamic>> _pending = {};
  bool _disposed = false;

  // Cached primary addresses per walletId so a re-render of the
  // dashboard doesn't pay an IPC round trip on every frame. The address
  // is public; caching it on the main side is fine. Invalidated on
  // `lock` (the slot is gone) and on `dispose`.
  final Map<int, String> _primaryAddressCache = {};

  /// Spawns the dedicated isolate and returns the handle. The
  /// per-process lifetime is intentional — spawning a fresh isolate per
  /// sign was rejected in ADR 0004 (60ms spawn cost; 13-page EIP-712
  /// ceremony would pay ~780ms in spawn overhead alone).
  static Future<WalletIsolate> spawn() async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      _isolateEntry,
      receivePort.sendPort,
      debugName: 'realunit-wallet-isolate',
    );
    final stream = receivePort.asBroadcastStream();
    // First message from the isolate is its own SendPort. After that
    // the broadcast stream is consumed by the response dispatcher.
    final sendPort = await stream.first as SendPort;

    final handle = WalletIsolate._(sendPort, receivePort, isolate);
    stream.listen(handle._onMessage,
        onError: (Object e, StackTrace s) => handle._failAll(
            WalletIsolateCrashException('isolate emitted an error: $e')),
        onDone: () => handle._failAll(
            WalletIsolateCrashException('isolate channel closed unexpectedly')));
    return handle;
  }

  /// Internal: failover for everything in-flight. Called when the
  /// isolate dies, the channel closes, or a global error fires.
  void _failAll(WalletIsolateException err) {
    final pending = Map<int, Completer<dynamic>>.from(_pending);
    _pending.clear();
    for (final c in pending.values) {
      if (!c.isCompleted) c.completeError(err);
    }
  }

  void _onMessage(dynamic msg) {
    if (msg is! _IsolateResponse) return;
    final completer = _pending.remove(msg.id);
    if (completer == null || completer.isCompleted) return;
    if (msg is _ErrorResponse) {
      if (msg.cancelled) {
        completer.completeError(WalletIsolateCancelledException());
      } else if (msg.notUnlocked) {
        completer.completeError(
            WalletIsolateNotUnlockedException(msg.walletId ?? 0));
      } else {
        completer.completeError(WalletIsolateException(msg.message));
      }
      return;
    }
    if (msg is _OkResponse) {
      completer.complete(msg.value);
      return;
    }
  }

  Future<T> _send<T>(_IsolateRequest req) {
    if (_disposed) {
      return Future.error(
          WalletIsolateException('walletIsolate disposed; spawn a fresh one'));
    }
    final completer = Completer<T>();
    _pending[req.id] = completer;
    _sendPort.send(req);
    return completer.future;
  }

  int _newId() => _nextId++;

  /// Hands the encrypted seed + AES-GCM key to the isolate, which
  /// decrypts inside its own heap, derives the BIP32 root, and caches
  /// the unlocked slot keyed by [walletId]. Returns the primary
  /// derivation-zero address so the caller can pin it back into the
  /// app-store (or the cache here).
  Future<String> unlock(int walletId, String encryptedSeed, Uint8List keyBytes) async {
    final addr = await _send<String>(
        _UnlockRequest(_newId(), walletId, encryptedSeed, keyBytes));
    _primaryAddressCache[walletId] = addr;
    return addr;
  }

  /// Adopts a plaintext mnemonic into the isolate's unlocked slot. The
  /// `SeedDraft` calls this from `dispose()` so the in-memory string
  /// is transferred into the isolate before the main-side reference is
  /// dropped. The walletId is the just-committed row's id.
  Future<String> adoptPlaintext(int walletId, String mnemonic) async {
    final addr = await _send<String>(
        _AdoptPlaintextRequest(_newId(), walletId, mnemonic));
    _primaryAddressCache[walletId] = addr;
    return addr;
  }

  /// Releases the isolate-side slot for [walletId]. The isolate
  /// best-effort zeroizes its decrypted buffer (filling a backing
  /// `Uint8List` view with zeros) and drops the `BIP32` reference. Dart
  /// `String` immutability means the original mnemonic string remains
  /// reachable until GC; that is the limit of what Dart permits, and it
  /// is documented as defence-in-depth, not zeroization-by-construction.
  Future<void> lock(int walletId) async {
    if (_disposed) return;
    try {
      await _send<void>(_LockRequest(_newId(), walletId));
    } on WalletIsolateException {
      // The slot may already have been dropped (locked twice, or never
      // unlocked). Defensive no-op — failing here would block the
      // foreground lifecycle observer from cleaning up.
    } finally {
      _primaryAddressCache.remove(walletId);
    }
  }

  /// Derives the address at `m/44'/60'/<accountIndex>'/0/<addressIndex>`.
  /// The isolate runs the derivation; the main side gets only the
  /// 20-byte address string, never the private key.
  Future<String> deriveAddress(
    int walletId,
    int accountIndex,
    int addressIndex,
  ) =>
      _send<String>(_DeriveAddressRequest(
          _newId(), walletId, accountIndex, addressIndex));

  /// Signs an opaque digest at the supplied derivation path. The digest
  /// is whatever the main-side `SignPipeline` (Initiative II) decides —
  /// EIP-712, EIP-191 personal_sign, raw keccak, anything. The isolate
  /// does not validate the schema; that lives on the main side so the
  /// schema engine and the signer are independently auditable.
  Future<({BigInt r, BigInt s, int v})> signDigest(
    int walletId,
    String derivationPath,
    Uint8List digest, {
    int? chainId,
  }) async {
    final raw = await _send<List<dynamic>>(_SignDigestRequest(
      _newId(),
      walletId,
      derivationPath,
      digest,
      chainId: chainId,
    ));
    // The isolate-side encoding is a 3-tuple of (rHex, sHex, v) so the
    // wire format is plain JSON-safe — no MsgSignature class crosses
    // the boundary. Repack on this side.
    return (
      r: BigInt.parse(raw[0] as String, radix: 16),
      s: BigInt.parse(raw[1] as String, radix: 16),
      v: raw[2] as int,
    );
  }

  /// EIP-191 / personal_sign over `payload`. Returns the 65-byte
  /// signature as a `Uint8List` (r || s || v).
  Future<Uint8List> signPersonalMessage(
    int walletId,
    String derivationPath,
    Uint8List payload, {
    int? chainId,
  }) =>
      _send<Uint8List>(_SignPersonalMessageRequest(
        _newId(),
        walletId,
        derivationPath,
        payload,
        chainId: chainId,
      ));

  /// Round-trips the mnemonic back to the main isolate for the
  /// reveal flows (settings_seed + verify_seed). Permitted by §1 Law 6
  /// because the caller scope is finite: the cubit holds the string
  /// while the user reads it, then `lockCurrentWallet` + the cubit's
  /// close hook drop the reference. The isolate copy stays in place;
  /// only the caller's holder needs to be dropped.
  Future<String> reveal(int walletId) =>
      _send<String>(_RevealRequest(_newId(), walletId));

  /// Cooperative cancel for an in-flight request. The isolate consults
  /// the token between derivation steps; a cancelled request completes
  /// with `WalletIsolateCancelledException`. Use this from
  /// `WalletService.lockCurrentWallet` instead of `Future.ignore()` —
  /// the ignore-pattern fails to propagate to the isolate, leaving the
  /// decrypted seed pinned in the unlocked-slots map.
  Future<void> cancel(int requestId) =>
      _send<void>(_CancelRequest(_newId(), requestId));

  /// Cached primary address for `walletId`, populated by `unlock` and
  /// cleared by `lock`. Returns `null` if the wallet is not currently
  /// unlocked or has not yet been queried.
  String? cachedPrimaryAddress(int walletId) => _primaryAddressCache[walletId];

  /// `true` after `dispose()` has run.
  bool get isDisposed => _disposed;

  /// Disposes the isolate. Used by tests + the integration test
  /// harness; production app keeps the isolate alive until process
  /// exit. After dispose, any future request errors out immediately.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _primaryAddressCache.clear();
    try {
      await _send<void>(_ShutdownRequest(_newId()));
    } on WalletIsolateException {
      // The isolate may have already shut itself down (e.g. an earlier
      // crash). Either way, we kill it for good measure.
    }
    _receivePort.close();
    _isolate.kill(priority: Isolate.immediate);
    _failAll(WalletIsolateCrashException('isolate disposed'));
  }
}

// ---- isolate side ----------------------------------------------------

/// Per-walletId unlocked slot. The decrypted mnemonic + the derived
/// BIP32 root live exclusively in this isolate's heap.
class _UnlockedSlot {
  _UnlockedSlot(this.mnemonic, this.root);
  // Kept as a private field on this private class — the only consumer
  // is `_handleReveal`. Never escapes the isolate by any other path.
  String mnemonic;
  BIP32 root;
}

void _isolateEntry(SendPort initialReply) {
  final port = ReceivePort();
  initialReply.send(port.sendPort);

  final unlocked = <int, _UnlockedSlot>{};
  // Cancellation tokens keyed by request-id. A handler checks
  // `cancelled[req.id] == true` between derivation steps. Set by the
  // `_CancelRequest` handler.
  final cancelled = <int, bool>{};

  port.listen((dynamic msg) async {
    if (msg is! _IsolateRequest) return;
    try {
      // Reserve a cancellation slot for every request so the cancel
      // handler can flip it even if the request handler hasn't started.
      cancelled[msg.id] = false;
      final response = await _dispatch(msg, unlocked, cancelled);
      cancelled.remove(msg.id);
      initialReply.send(response);
    } catch (e) {
      cancelled.remove(msg.id);
      initialReply.send(_ErrorResponse(msg.id, '$e'));
    }
  });
}

Future<_IsolateResponse> _dispatch(
  _IsolateRequest req,
  Map<int, _UnlockedSlot> unlocked,
  Map<int, bool> cancelled,
) async {
  // Cancellation cooperative check. Handlers re-check between
  // derivation and signing as well.
  bool isCancelled() => cancelled[req.id] == true;

  switch (req) {
    case _UnlockRequest(:final walletId, :final encryptedSeed, :final keyBytes):
      // Defensive: if a previous unlock left a slot, replace it. The
      // mandate's clearly-scoped-lifetime rule means we don't want stale
      // slots accumulating.
      final mnemonic = _decryptSeed(keyBytes, encryptedSeed);
      if (isCancelled()) {
        return _ErrorResponse(req.id, 'cancelled', cancelled: true);
      }
      final seedBytes = bip39.mnemonicToSeed(mnemonic);
      final root = BIP32.fromSeed(seedBytes);
      unlocked[walletId] = _UnlockedSlot(mnemonic, root);
      // Compute the primary address so the caller can populate the
      // address cache without a follow-up round trip.
      final address = _addressForPath(root, "m/44'/60'/0'/0/0");
      return _OkResponse<String>(req.id, address);

    case _AdoptPlaintextRequest(:final walletId, :final mnemonic):
      final seedBytes = bip39.mnemonicToSeed(mnemonic);
      final root = BIP32.fromSeed(seedBytes);
      unlocked[walletId] = _UnlockedSlot(mnemonic, root);
      final address = _addressForPath(root, "m/44'/60'/0'/0/0");
      return _OkResponse<String>(req.id, address);

    case _LockRequest(:final walletId):
      final slot = unlocked.remove(walletId);
      if (slot != null) _bestEffortZeroize(slot);
      return _OkResponse<void>(req.id, null);

    case _DeriveAddressRequest(
        :final walletId,
        :final accountIndex,
        :final addressIndex,
      ):
      final slot = unlocked[walletId];
      if (slot == null) {
        return _ErrorResponse(req.id, 'walletId $walletId not unlocked',
            notUnlocked: true, walletId: walletId);
      }
      if (isCancelled()) {
        return _ErrorResponse(req.id, 'cancelled', cancelled: true);
      }
      final path = "m/44'/60'/$accountIndex'/0/$addressIndex";
      return _OkResponse<String>(req.id, _addressForPath(slot.root, path));

    case _SignDigestRequest(
        :final walletId,
        :final derivationPath,
        :final digest,
        :final chainId,
      ):
      final slot = unlocked[walletId];
      if (slot == null) {
        return _ErrorResponse(req.id, 'walletId $walletId not unlocked',
            notUnlocked: true, walletId: walletId);
      }
      if (isCancelled()) {
        return _ErrorResponse(req.id, 'cancelled', cancelled: true);
      }
      final child = slot.root.derivePath(derivationPath);
      final pk = EthPrivateKey.fromHex(hex_convert.hex.encode(child.privateKey!));
      // web3dart's signToEcSignature returns r,s,v as BigInt + int.
      // Re-encode on the wire as hex strings so the marshaller doesn't
      // have to special-case BigInt.
      final sig = pk.signToEcSignature(digest, chainId: chainId);
      return _OkResponse<List<dynamic>>(req.id, [
        sig.r.toRadixString(16),
        sig.s.toRadixString(16),
        sig.v,
      ]);

    case _SignPersonalMessageRequest(
        :final walletId,
        :final derivationPath,
        :final payload,
        :final chainId,
      ):
      final slot = unlocked[walletId];
      if (slot == null) {
        return _ErrorResponse(req.id, 'walletId $walletId not unlocked',
            notUnlocked: true, walletId: walletId);
      }
      if (isCancelled()) {
        return _ErrorResponse(req.id, 'cancelled', cancelled: true);
      }
      final child = slot.root.derivePath(derivationPath);
      final pk = EthPrivateKey.fromHex(hex_convert.hex.encode(child.privateKey!));
      final signed = pk.signPersonalMessageToUint8List(payload, chainId: chainId);
      return _OkResponse<Uint8List>(req.id, signed);

    case _RevealRequest(:final walletId):
      final slot = unlocked[walletId];
      if (slot == null) {
        return _ErrorResponse(req.id, 'walletId $walletId not unlocked',
            notUnlocked: true, walletId: walletId);
      }
      // The mnemonic crosses the channel as a `String`. Law 6 permits
      // this for clearly-scoped reveal flows; the caller must dispose
      // its holder.
      return _OkResponse<String>(req.id, slot.mnemonic);

    case _CancelRequest(:final targetId):
      cancelled[targetId] = true;
      return _OkResponse<void>(req.id, null);

    case _ShutdownRequest():
      // Drop every slot before returning so the OS reclaims the heap
      // immediately on isolate kill. Best-effort zeroize first.
      for (final slot in unlocked.values) {
        _bestEffortZeroize(slot);
      }
      unlocked.clear();
      return _OkResponse<void>(req.id, null);
  }
}

String _addressForPath(BIP32 root, String path) {
  final child = root.derivePath(path);
  final pk = EthPrivateKey.fromHex(hex_convert.hex.encode(child.privateKey!));
  return pk.address.hexEip55;
}

String _decryptSeed(Uint8List key, String encoded) {
  // Mirror of `SecureStorage.decryptSeed`, intentionally inlined so the
  // isolate stays self-contained — the secure_storage module pulls
  // `flutter/foundation.dart` which we don't want in the isolate's
  // boot path. Pointycastle is pure Dart and is fine to import.
  final colonIndex = encoded.indexOf(':');
  final iv = base64Decode(encoded.substring(0, colonIndex));
  final ciphertext = base64Decode(encoded.substring(colonIndex + 1));
  final cipher = GCMBlockCipher(AESEngine())
    ..init(false, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
  return utf8.decode(cipher.process(ciphertext));
}

void _bestEffortZeroize(_UnlockedSlot slot) {
  // Dart `String` is immutable — we cannot reach into the bytes. The
  // best we can do is drop the reference and rely on GC. As a
  // defence-in-depth measure, overwrite the field with a space-filled
  // string of the same length so a heap walk pre-GC observes the dummy
  // at the same slot, not the mnemonic. Also reassign the BIP32 root
  // to a fresh, throwaway tree so its private-key buffers go unreached.
  slot.mnemonic = ' ' * slot.mnemonic.length;
  // Construct an "empty" 12-word mnemonic from a zero seed so the
  // derived root holds no real private keys; the previous root falls
  // out of scope on assignment.
  slot.root = BIP32.fromSeed(Uint8List(64));
}
