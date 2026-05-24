import 'dart:async';
import 'dart:developer' as developer;

import 'package:bitbox_flutter/bitbox_flutter.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_connection_status.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_credentials.dart';

// MIGRATION NOTE — Initiative I, ADR 0001 (docs/adr/0001-bitbox-connection-lifecycle.md)
//
// _isConnected removed; subscribe to status stream (or read currentStatus
// for the latest replayed value). The Stream<BitboxConnectionStatus> owned
// by BitboxService is the sole source of truth for the connect-state. Every
// other consumer — BitboxCredentials, ConnectBitboxCubit, HomeBloc — must
// derive its view of "are we connected?" from currentStatus or from a
// subscription. The pre-existing bool getter on BitboxCredentials is now a
// derived view (delegates to `bitboxManager != null`) and is preserved only
// for backward compatibility with sign-path call sites that already snapshot
// it.

/// Owns the lifecycle of the paired BitBox device.
///
/// ADR 0001 declares this service as the single source of truth for the
/// BitBox connect-state. Every transition flows through [status] — a
/// broadcast stream with replay-last-value semantics. Consumers subscribe
/// and receive the current state synchronously, plus every subsequent
/// transition.
///
/// Internal contract:
///   - [_lastStatus] is the canonical "where are we now". Mutated only by
///     [_emit], which also writes to [_statusController].
///   - [init], [clear], [signalDeviceLost], [dispose] are the only public
///     transition triggers.
///   - The periodic observer is an internal driver of [status]; it never
///     mutates [_lastStatus] directly — it routes through [_emit] like
///     every other transition source.
class BitboxService {
  // Observer poll period is widened in production and tightened in tests so
  // device-loss-recovery behaviour can be exercised in real time without
  // five-second sleeps.
  BitboxService({Duration connectionStatusInterval = const Duration(seconds: 5)})
    : _connectionStatusInterval = connectionStatusInterval;

  final BitboxManager bitboxManager = BitboxManager();
  final Duration _connectionStatusInterval;
  // Keyed by the lowercased address so multi-wallet (future) reconnect
  // re-attaches every active set of credentials, not just the most recently
  // handed out. Lowercase invariant: callers may hand in EIP-55-mixed or raw
  // hex — we normalise via [_key] on every read/write so a checksum-flip
  // can't fork the map.
  final Map<String, BitboxCredentials> _credentialsByAddress = {};

  /// Broadcast controller for the lifecycle stream. Late subscribers replay
  /// the cached [_lastStatus] synchronously via [status] before joining the
  /// live broadcast.
  final StreamController<BitboxConnectionStatus> _statusController =
      StreamController<BitboxConnectionStatus>.broadcast();

  /// Canonical "where are we now" — every emission to [_statusController]
  /// also writes here so [currentStatus] and the replay-on-subscribe path
  /// stay in sync.
  BitboxConnectionStatus _lastStatus = const Disconnected();

  /// Shared future for an in-flight [init] so concurrent callers receive the
  /// same result without racing a second `bitboxManager.connect()`. Property
  /// test pinned: for any N concurrent [init] calls, exactly one underlying
  /// `initBitBox()` invocation.
  Future<BitboxConnectionStatus>? _pendingInit;

  Timer? _connectionStatusObserver;
  Future<void>? _pendingDisconnect;
  bool _disposed = false;

  /// Normalises an address into the form used as the map key. Lowercase is
  /// the cheapest robust choice — EIP-55 checksum differs in casing only, so
  /// `0xAbC` and `0xabc` collapse to the same entry.
  String _key(String address) => address.toLowerCase();

  /// Latest broadcast value (replay-last semantics). Cheap to read; no
  /// allocation.
  BitboxConnectionStatus get currentStatus => _lastStatus;

  /// Broadcast lifecycle stream. Late subscribers receive the latest cached
  /// status synchronously as their first event (replay-last-value), then
  /// follow every transition until the controller is closed by [dispose].
  Stream<BitboxConnectionStatus> get status {
    // Replay-last pattern hand-rolled (rxdart not in pubspec). We wire the
    // per-subscriber controller eagerly to the broadcast stream BEFORE
    // delivering the replayed value — an `async*` generator that does
    // `yield initial; yield* upstream;` would subscribe to upstream only
    // after the first yield was consumed, so any transition emitted between
    // the test's `service.status.listen(...)` and the next microtask hop
    // would be dropped by the broadcast controller (no listener yet). The
    // listener-attached-then-replay order below preserves every transition.
    final controller = StreamController<BitboxConnectionStatus>();
    late StreamSubscription<BitboxConnectionStatus> upstreamSub;
    controller.onListen = () {
      upstreamSub = _statusController.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      // Replay the latest cached value AFTER the upstream subscription is
      // installed. If an `_emit` ran synchronously between this getter
      // returning and the consumer's `.listen` call, it lands inside the
      // broadcast stream's pending queue and will surface to upstreamSub
      // on the next microtask hop — never silently dropped.
      controller.add(_lastStatus);
    };
    controller.onCancel = () => upstreamSub.cancel();
    return controller.stream;
  }

  void _emit(BitboxConnectionStatus next) {
    if (_disposed) return;
    if (_lastStatus == next) return; // de-dup identical consecutive states.
    _lastStatus = next;
    _statusController.add(next);
  }

  Future<List<BitboxDevice>> getAllUsbDevices() => bitboxManager.devices;

  Future<bool> startScan() => bitboxManager.startScan();

  BitboxCredentials getCredentials(String address) {
    final credentials = _credentialsByAddress.putIfAbsent(
      _key(address),
      () => BitboxCredentials(address, _onCredentialsSignQueueTimeout),
    );
    final live = _lastStatus is Paired || _lastStatus is InUse;
    if (live) {
      credentials.setBitbox(bitboxManager);
    }
    return credentials;
  }

  /// Pairs the given device.
  ///
  /// Concurrent callers share a single in-flight future via [_pendingInit] —
  /// the SDK sees exactly one `bitboxManager.connect()` + `initBitBox()` per
  /// concurrent batch. A redundant [init] against an already-paired device
  /// short-circuits to the current [Paired] status without re-issuing any
  /// native call.
  Future<BitboxConnectionStatus> init(BitboxDevice device) async {
    if (_disposed) {
      throw StateError(
        'BitboxService.init called after dispose; create a new service.',
      );
    }
    // Idempotent fast-path: if we already reached Paired for the same
    // session, just return it. Prevents a redundant init() (e.g. a fast
    // `checkForBitbox` tick re-entering during a stable pair) from kicking
    // a second handshake on the live noise channel.
    if (_lastStatus is Paired || _lastStatus is InUse) {
      return _lastStatus;
    }
    // Coalesce concurrent callers onto the single in-flight future.
    final pending = _pendingInit;
    if (pending != null) return pending;
    final future = _runInit(device);
    _pendingInit = future;
    try {
      return await future;
    } finally {
      // Only the caller that started the init clears the slot; later joiners
      // observe the field already nulled and skip the clear.
      if (identical(_pendingInit, future)) _pendingInit = null;
    }
  }

  Future<BitboxConnectionStatus> _runInit(BitboxDevice device) async {
    // The disconnect observer fires .disconnect() asynchronously when the
    // device drops. If the user re-plugs immediately we'd race two ops on
    // the same SDK manager and the result is undefined. Wait for any
    // in-flight disconnect to finish first.
    await _pendingDisconnect;
    _emit(Connecting(device));
    try {
      await bitboxManager.connect(device);
      final didInit = await bitboxManager.initBitBox();
      if (!didInit) {
        // Failure walks back to Disconnected so the cubit can decide to
        // retry; we deliberately surface the typed status BEFORE rethrowing
        // so a subscriber that only listens for state transitions sees the
        // bounce without depending on the throw site.
        _emit(const Disconnected());
        throw Exception('Failed to init');
      }
      // Re-attach the manager to every active credentials instance so
      // existing wallets heal automatically on reconnect. The previous
      // derivationPath is preserved inside setBitbox().
      for (final credentials in _credentialsByAddress.values) {
        credentials.setBitbox(bitboxManager);
      }
      // Paired emitted ONLY after the credentials fan-out completes —
      // closes F-032: a sign racing through getCredentials() on another
      // isolate can no longer observe "connected" while credentials are
      // detached.
      _emit(Paired(device));
      return _lastStatus;
    } catch (e) {
      if (_lastStatus is Connecting) {
        _emit(const Disconnected());
      }
      rethrow;
    }
  }

  /// Tears down the active pairing (if any), empties the credentials map,
  /// stops the observer, and walks Paired/Lost → Disconnecting → Disconnected.
  /// Idempotent: clearing from Disconnected is a no-op.
  Future<void> clear() async {
    if (_disposed) return;
    if (_lastStatus is Disconnected) return;
    _emit(const Disconnecting());
    stopConnectionStatusObserver();
    for (final credentials in _credentialsByAddress.values) {
      credentials.clearBitbox();
    }
    _credentialsByAddress.clear();
    _pendingDisconnect = _disconnectAndForget();
    await _pendingDisconnect;
    _pendingDisconnect = null;
    _emit(const Disconnected());
  }

  /// Signals that the previously-paired device has been lost mid-session
  /// for the given [reason]. Only valid from [Paired] / [InUse] — from any
  /// other state this is a no-op (a stale credentials reference firing
  /// after clear() must NOT emit a synthetic Lost).
  ///
  /// Emits [Lost], detaches every credentials in the map, and tears down
  /// the observer. The consumer must call [clear] to walk to [Disconnected]
  /// before a fresh [init] can succeed.
  void signalDeviceLost(LostReason reason) {
    if (_disposed) return;
    final current = _lastStatus;
    if (current is! Paired && current is! InUse) return;
    for (final credentials in _credentialsByAddress.values) {
      credentials.clearBitbox();
    }
    stopConnectionStatusObserver();
    _emit(Lost(reason));
  }

  /// Hot-restart and end-of-app cleanup. Closes the broadcast controller so
  /// every active subscription's `onDone` fires; rejects subsequent [init]
  /// with a [StateError]. Idempotent.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    stopConnectionStatusObserver();
    for (final credentials in _credentialsByAddress.values) {
      credentials.clearBitbox();
    }
    _credentialsByAddress.clear();
    // Terminal emission must happen BEFORE the controller is closed so
    // late subscribers replay the final Disconnected and onDone-listeners
    // see the closing event. _emit short-circuits on _disposed — write
    // directly here.
    if (_lastStatus is! Disconnected) {
      _lastStatus = const Disconnected();
      _statusController.add(const Disconnected());
    }
    await _statusController.close();
  }

  /// Internal callback wired into every [BitboxCredentials] instance so the
  /// sign-queue timeout propagates back to the service without the
  /// credentials having to reach back through a singleton getter. Closure-
  /// based to keep the dependency uni-directional (service owns credentials,
  /// never the other way round).
  void _onCredentialsSignQueueTimeout() {
    signalDeviceLost(LostReason.signQueueTimeout);
  }

  void startConnectionStatusObserver() {
    if (_disposed) return;
    _connectionStatusObserver?.cancel();
    _connectionStatusObserver = Timer.periodic(_connectionStatusInterval, (_) async {
      final List<BitboxDevice> devices;
      try {
        devices = await getAllUsbDevices();
      } catch (e) {
        // Transient BLE/USB hiccups inside the periodic callback used to
        // surface as uncaught async errors and kill the recovery loop. Log
        // and wait for the next tick — only an explicit empty device list
        // is allowed to trigger the device-loss path below.
        developer.log('device probe failed in observer tick: $e', name: '$BitboxService');
        return;
      }
      if (devices.isEmpty) {
        // Two ticks can fire back-to-back if the body's awaits straddle the
        // next interval — bail unless we're still in the live state.
        // currentStatus acts as the single-writer guard because we emit Lost
        // (which also stops the observer) before any further work.
        final current = _lastStatus;
        if (current is! Paired && current is! InUse) return;
        // Detach credentials and stop the observer BEFORE issuing the
        // disconnect so any callback racing on the manager sees a clean
        // detach.
        for (final credentials in _credentialsByAddress.values) {
          credentials.clearBitbox();
        }
        stopConnectionStatusObserver();
        _emit(const Lost(LostReason.deviceUnreachable));
        // Close the underlying transport. Required on Android so the USB
        // file-descriptor is released — otherwise the next connect() can
        // fail because the OS still considers the device claimed. Safe on
        // iOS where the BLE link is already gone at this point.
        _pendingDisconnect = _disconnectAndForget();
        await _pendingDisconnect;
        _pendingDisconnect = null;
      }
    });
  }

  Future<void> _disconnectAndForget() async {
    try {
      await bitboxManager.disconnect();
    } on Exception catch (e) {
      developer.log('disconnect after device-loss failed: $e', name: '$BitboxService');
    }
  }

  void stopConnectionStatusObserver() {
    _connectionStatusObserver?.cancel();
    _connectionStatusObserver = null;
  }

  /// Get channel hash - this is shown on the BitBox device
  Future<String> getChannelHash() async {
    final hash = await bitboxManager.getChannelHash();
    return hash;
  }

  /// Confirm pairing after user verified on BitBox device
  Future<void> confirmPairing() async {
    final didVerify = await bitboxManager.channelHashVerify();
    if (!didVerify) throw Exception('Failed to verify');
  }
}
