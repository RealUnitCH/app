import 'dart:convert' show utf8;
import 'dart:typed_data';

import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';
import 'package:realunit_wallet/packages/wallet/wallet_isolate.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

enum WalletType { software, bitbox, debug }

abstract class AWallet {
  WalletType get walletType;
  final int id;
  String name;

  /// The Primary account is the account derived from the account index 0
  AWalletAccount get primaryAccount;
  AWalletAccount get currentAccount;

  AWallet(this.id, this.name);
}

/// Software wallet handle — post-Initiative-IV (BL-018), this class
/// never holds the BIP39 mnemonic as a long-lived field. The plaintext
/// lives in the dedicated [WalletIsolate]; the main isolate keeps only
/// the public address, the wallet identity, and a reference to the
/// isolate so every sign call can be marshalled across.
///
/// Lifecycle:
///   - Construction binds the handle to the isolate-side slot keyed by
///     `id`. The slot itself is created by `WalletService` via either
///     `WalletIsolate.adoptPlaintext` (onboarding/restore) or
///     `WalletIsolate.unlock` (app start with persisted ciphertext).
///   - Lock invalidates the slot but does not invalidate the handle —
///     the handle gets re-paired with a fresh slot on the next unlock.
///     The view-wallet replacement happens at the `AppStore` level so
///     attempting to sign through a stale handle throws via the
///     isolate's `NotUnlocked` error.
///
/// Display flows (verify-seed quiz, settings-seed reveal) use a
/// separate [SeedDraft] value object that is created scope-locally —
/// see `WalletService.generateUncommittedSeedDraft` and
/// `WalletService.revealSeed`. Law 6 permits the seed string on the
/// main isolate inside a clearly-scoped function.
class SoftwareWallet extends AWallet {
  @override
  WalletType get walletType => WalletType.software;

  /// Public Ethereum address derived from the primary account
  /// (`m/44'/60'/0'/0/0`). Cached on the handle so renders that only
  /// need the address (the vast majority — balance, receive QR, etc.)
  /// don't pay an IPC round trip.
  final String address;

  final WalletIsolate _isolate;

  @override
  late final WalletAccount primaryAccount;

  late WalletAccount _currentAccount;

  @override
  WalletAccount get currentAccount => _currentAccount;

  /// `id` is the persisted wallet row's primary key; it doubles as the
  /// isolate-side slot key so concurrent multi-wallet support (a later
  /// initiative) needs no schema change here.
  SoftwareWallet(super.id, super.name, this.address, this._isolate) {
    primaryAccount = WalletAccount(_isolate, id, 0, address);
    _currentAccount = primaryAccount;
  }

  /// Selects a different account index. The address for the new
  /// account is derived lazily on first sign through the isolate; this
  /// constructor takes a placeholder address so the caller can pin
  /// the public-facing address before the round trip completes.
  void selectAccount(int index, String addressForIndex) =>
      _currentAccount = WalletAccount(_isolate, id, index, addressForIndex);
}

/// Software wallet without the mnemonic in memory — only the public address is
/// cached. Used at app startup so the dashboard renders before the (expensive
/// and rarely needed) BIP32 derivation happens. Must be upgraded to a full
/// [SoftwareWallet] via `WalletService.unlockCurrentWallet` before any sign
/// operation.
class SoftwareViewWallet extends AWallet {
  @override
  WalletType get walletType => WalletType.software;

  @override
  late final SoftwareViewWalletAccount primaryAccount;

  late SoftwareViewWalletAccount _currentAccount;

  @override
  SoftwareViewWalletAccount get currentAccount => _currentAccount;

  SoftwareViewWallet(super.id, super.name, String address) {
    primaryAccount = SoftwareViewWalletAccount(0, _LockedCredentials(address));
    _currentAccount = primaryAccount;
  }
}

/// Transient holder of a BIP39 mnemonic on the main isolate. The only
/// legitimate callers are:
///
///   - `WalletService.generateUncommittedSeedDraft` (onboarding new
///     wallet — the draft is held in `CreateWalletCubit.state` while
///     the user copies the words; verify-seed consumes it and the
///     commit path adopts the plaintext into the isolate).
///   - `WalletService.restoreWallet`'s internal draft (user-typed
///     mnemonic; same adoption path, no quiz step).
///   - `WalletService.revealSeed` (settings-seed flow — round-trips
///     the mnemonic from the isolate so the user can see the words).
///
/// The class is intentionally not a `SoftwareWallet`: there is no
/// `id` (the wallet may not be persisted yet) and no sign primitives.
/// Holders must call [dispose] as soon as the displayed words are no
/// longer needed; the dispose overwrites the inner field with spaces
/// so a heap walk pre-GC sees the dummy at the same slot, not the
/// mnemonic.
///
/// SECURITY: BIP39 lifetime — see BL-018. The draft lifetime is the
/// scope of the holding cubit; lifecycle observers must call [dispose]
/// on hidden so the seed doesn't make it into an iOS app-suspend
/// snapshot.
class SeedDraft {
  SeedDraft(String mnemonic, {this.name}) : _mnemonic = mnemonic;

  /// Optional wallet name carried alongside the draft so the
  /// onboarding flow can hand a single value through the screens
  /// without a sibling field.
  final String? name;

  // Mutable so [dispose] can overwrite the field. `final` would defeat
  // the best-effort zeroize.
  String _mnemonic;

  // Once disposed, subsequent reads throw. Callers that race
  // (e.g. the verify quiz reading mnemonic while the lifecycle
  // observer disposes) get a typed `StateError` instead of an empty
  // string they might silently render.
  bool _disposed = false;

  String get mnemonic {
    if (_disposed) {
      throw StateError('SeedDraft accessed after dispose — '
          'the BIP39 reference was cleared; spawn a new draft.');
    }
    return _mnemonic;
  }

  /// The 12 / 24 words split on whitespace, dropping empty tokens.
  /// Identical semantics to the legacy `String.seedWords` extension so
  /// the verify-quiz and reveal flows can keep their existing logic
  /// without re-parsing the mnemonic across the boundary.
  List<String> get seedWords =>
      mnemonic.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

  /// `true` after [dispose] runs. Lifecycle observers consult this
  /// before re-disposing on a second `hidden` event.
  bool get isDisposed => _disposed;

  /// Best-effort zeroize the held string. Dart `String` is immutable;
  /// the assignment swaps the field to a same-length space-filled
  /// string so a heap walk pre-GC observes the dummy in the old field
  /// slot. The original buffer remains reachable through the literal
  /// pool if it was a const, but the only path that produced this
  /// instance was `bip39.generateMnemonic()` (a fresh allocation) or
  /// the isolate's `_RevealRequest` response (a fresh String from the
  /// isolate's heap), neither of which is const-pooled.
  void dispose() {
    if (_disposed) return;
    _mnemonic = ' ' * _mnemonic.length;
    _disposed = true;
  }
}

// Every sign path is unreachable while [WalletService.ensureCurrentWalletUnlocked]
// runs before the credentials are used. Hitting any of these would mean a new
// caller forgot to call it — surface that immediately in dev via [assert] and
// fall through to a plain [StateError] (programmer error) in release, instead
// of a typed exception that the rest of the app would have to catch and route.
class _LockedCredentials extends CredentialsWithKnownAddress {
  final EthereumAddress _address;

  _LockedCredentials(String hexAddress) : _address = EthereumAddress.fromHex(hexAddress);

  @override
  EthereumAddress get address => _address;

  // The `throw StateError(...)` lines below are defensive fallthroughs: in
  // debug builds the `assert(false, ...)` above already trips and surfaces an
  // AssertionError, so the throw is unreachable. In release the assert is
  // stripped and the throw becomes the live signal, but the test suite runs
  // in debug — line-coverage instrumentation never marks the throws as
  // executed. `// coverage:ignore-line` reflects that without hiding the
  // behavioural contract (still exercised via `throwsA(isA<Error>())`).
  @override
  MsgSignature signToEcSignature(Uint8List payload, {int? chainId, bool isEIP1559 = false}) {
    assert(false, _viewWalletProgrammerError);
    throw StateError(_viewWalletProgrammerError); // coverage:ignore-line
  }

  @override
  Future<MsgSignature> signToSignature(Uint8List payload, {int? chainId, bool isEIP1559 = false}) {
    assert(false, _viewWalletProgrammerError);
    throw StateError(_viewWalletProgrammerError); // coverage:ignore-line
  }

  @override
  Future<Uint8List> signPersonalMessage(Uint8List payload, {int? chainId}) {
    assert(false, _viewWalletProgrammerError);
    throw StateError(_viewWalletProgrammerError); // coverage:ignore-line
  }

  @override
  Uint8List signPersonalMessageToUint8List(Uint8List payload, {int? chainId}) {
    assert(false, _viewWalletProgrammerError);
    throw StateError(_viewWalletProgrammerError); // coverage:ignore-line
  }
}

const _viewWalletProgrammerError =
    'SoftwareViewWallet credentials reached a sign call — '
    'every signing path must await WalletService.ensureCurrentWalletUnlocked() first.';

class SoftwareViewWalletAccount extends AWalletAccount {
  SoftwareViewWalletAccount(super.accountIndex, super.primaryAddress);

  // Programmer error: callers must await WalletService.ensureCurrentWalletUnlocked
  // before signing. The locked credentials on this account already assert on the
  // same path, so this method is reachable only when the caller bypasses the
  // wallet's primaryAddress and calls signMessage directly. The `throw
  // StateError(...)` below is the release-mode fallthrough — debug builds trip
  // the assert(false) first, so line-coverage in test (debug) never reaches it.
  @override
  Future<String> signMessage(String message, {int addressIndex = 0}) {
    assert(
      false,
      'SoftwareViewWalletAccount.signMessage called without first '
      'awaiting WalletService.ensureCurrentWalletUnlocked()',
    );
    // coverage:ignore-start
    throw StateError(
      'SoftwareViewWalletAccount cannot sign while the mnemonic '
      'is locked — call WalletService.ensureCurrentWalletUnlocked() first.',
    );
    // coverage:ignore-end
  }
}

class BitboxWallet extends AWallet {
  @override
  WalletType get walletType => WalletType.bitbox;

  final BitboxService _bitboxService;

  @override
  late final BitboxWalletAccount primaryAccount;

  late BitboxWalletAccount _currentAccount;

  @override
  BitboxWalletAccount get currentAccount => _currentAccount;

  BitboxWallet(super.id, super.name, String address, this._bitboxService) {
    primaryAccount = BitboxWalletAccount(0, _bitboxService.getCredentials(address));
    _currentAccount = primaryAccount;
  }
}

class _DebugCredentials extends CredentialsWithKnownAddress {
  final EthereumAddress _address;

  _DebugCredentials(String hexAddress) : _address = EthereumAddress.fromHex(hexAddress);

  @override
  EthereumAddress get address => _address;

  @override
  MsgSignature signToEcSignature(Uint8List payload, {int? chainId, bool isEIP1559 = false}) =>
      throw UnsupportedError('Debug wallet cannot sign');

  @override
  Future<MsgSignature> signToSignature(Uint8List payload, {int? chainId, bool isEIP1559 = false}) =>
      throw UnsupportedError('Debug wallet cannot sign');

  @override
  Future<Uint8List> signPersonalMessage(Uint8List payload, {int? chainId}) =>
      throw UnsupportedError('Debug wallet cannot sign');

  @override
  Uint8List signPersonalMessageToUint8List(Uint8List payload, {int? chainId}) =>
      throw UnsupportedError('Debug wallet cannot sign');
}

class DebugWalletAccount extends AWalletAccount {
  DebugWalletAccount(String hexAddress) : super(0, _DebugCredentials(hexAddress));

  @override
  Future<String> signMessage(String message, {int addressIndex = 0}) =>
      throw UnsupportedError('Debug wallet cannot sign');
}

class DebugWallet extends AWallet {
  @override
  WalletType get walletType => WalletType.debug;

  final String address;
  late final DebugWalletAccount _account;

  @override
  DebugWalletAccount get primaryAccount => _account;

  @override
  DebugWalletAccount get currentAccount => _account;

  DebugWallet(super.id, super.name, this.address) {
    _account = DebugWalletAccount(address);
  }
}

/// Credentials for a [SoftwareWallet] account post-Initiative-IV. The
/// only path off the main isolate is `signPersonalMessage`, which
/// marshals across to [WalletIsolate]. Every synchronous sign method
/// (`signToEcSignature`, `signPersonalMessageToUint8List`) throws
/// `UnsupportedError` — the isolate boundary is fundamentally async
/// and no main-side cipher is available to satisfy the sync contract.
/// Callers that need bytes-back today must transition to the async
/// `signPersonalMessage` (Initiative II's `SignPipeline` is the
/// expected funnel).
class _IsolateCredentials extends CredentialsWithKnownAddress {
  _IsolateCredentials(this._isolate, this._walletId, this._accountIndex, String hexAddress)
      : _address = EthereumAddress.fromHex(hexAddress);

  final WalletIsolate _isolate;
  final int _walletId;
  final int _accountIndex;
  final EthereumAddress _address;

  @override
  EthereumAddress get address => _address;

  String get _derivationPath => "m/44'/60'/$_accountIndex'/0/0";

  @override
  MsgSignature signToEcSignature(Uint8List payload, {int? chainId, bool isEIP1559 = false}) =>
      throw UnsupportedError(_isolateSyncErrorMessage);

  @override
  Future<MsgSignature> signToSignature(Uint8List payload, {int? chainId, bool isEIP1559 = false}) async {
    final raw = await _isolate.signDigest(
      _walletId,
      _derivationPath,
      payload,
      chainId: chainId,
    );
    return MsgSignature(raw.r, raw.s, raw.v);
  }

  @override
  Future<Uint8List> signPersonalMessage(Uint8List payload, {int? chainId}) =>
      _isolate.signPersonalMessage(
        _walletId,
        _derivationPath,
        payload,
        chainId: chainId,
      );

  @override
  Uint8List signPersonalMessageToUint8List(Uint8List payload, {int? chainId}) =>
      throw UnsupportedError(_isolateSyncErrorMessage);
}

const _isolateSyncErrorMessage =
    'SoftwareWallet sign requires an async path post-Initiative-IV — '
    'the BIP32 root lives in the dedicated WalletIsolate and the IPC '
    'channel is async-only. Use signPersonalMessage / signToSignature '
    '(both Future-returning) instead.';

/// Account on a [SoftwareWallet]. `signMessage` round-trips through
/// the [WalletIsolate] so the BIP32 derivation happens off the main
/// isolate; the main side receives only the 65-byte signature bytes.
class WalletAccount extends AWalletAccount {
  WalletAccount(WalletIsolate isolate, int walletId, int accountIndex, String addressHex)
      : _isolate = isolate,
        _walletId = walletId,
        super(accountIndex,
            _IsolateCredentials(isolate, walletId, accountIndex, addressHex));

  final WalletIsolate _isolate;
  final int _walletId;

  @override
  Future<String> signMessage(String message, {int addressIndex = 0}) async {
    final path = "m/44'/60'/$accountIndex'/0/$addressIndex";
    final signed = await _isolate.signPersonalMessage(
      _walletId,
      path,
      utf8.encode(message),
    );
    return '0x${_hexEncode(signed)}';
  }
}

String _hexEncode(Uint8List bytes) {
  const chars = '0123456789abcdef';
  final buf = StringBuffer();
  for (final b in bytes) {
    buf.write(chars[(b >> 4) & 0xf]);
    buf.write(chars[b & 0xf]);
  }
  return buf.toString();
}
