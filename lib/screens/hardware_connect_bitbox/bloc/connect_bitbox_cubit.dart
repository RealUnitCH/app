import 'dart:async';
import 'dart:developer' as developer;

import 'package:bitbox_flutter/bitbox_flutter.dart' as sdk;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_connection_status.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/utils/device_info.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

part 'connect_bitbox_state.dart';

class ConnectBitboxCubit extends Cubit<BitboxConnectionState> {
  // Bound the host-side calls slightly above the native 60s BLE read timeout
  // so a dropped indication surfaces as BitboxNotConnected, not an endless
  // spinner.
  static const Duration _defaultConfirmPairingTimeout = Duration(seconds: 75);
  static const Duration _defaultCreateWalletTimeout = Duration(seconds: 30);

  // Outer cap on `init()` — the user has to press the pairing button on the
  // device while we wait. 120s is the SDK's own pairing-confirm budget plus a
  // small margin; anything beyond that almost certainly means the user
  // walked away and the device-side ephemeral noise channel has died.
  static const Duration _defaultPairingPinTimeout = Duration(seconds: 120);

  ConnectBitboxCubit(
    this._service,
    this._walletService,
    this._authService, {
    Duration confirmPairingTimeout = _defaultConfirmPairingTimeout,
    Duration createWalletTimeout = _defaultCreateWalletTimeout,
    Duration pairingPinTimeout = _defaultPairingPinTimeout,
  }) : _confirmPairingTimeout = confirmPairingTimeout,
       _createWalletTimeout = createWalletTimeout,
       _pairingPinTimeout = pairingPinTimeout,
       super(BitboxNotConnected()) {
    // Subscribe to the lifecycle Stream so a mid-session Lost (e.g. observer
    // device-vanish, sign-queue timeout) bounces the cubit to
    // BitboxNotConnected without forcing every internal try/catch to also
    // poll currentStatus. The subscription is cancelled in [close] to
    // prevent the stream from holding a reference to the closed cubit.
    _statusSub = _service.status.listen(_onServiceStatus);
    _startScanning();
  }

  final Duration _confirmPairingTimeout;
  final Duration _createWalletTimeout;
  final Duration _pairingPinTimeout;

  Future<void> _startScanning() async {
    if (DeviceInfo.instance.isIOS) await _service.startScan();
    _checkForTimer = Timer.periodic(const Duration(milliseconds: 500), (_) => checkForBitbox());
  }

  final BitboxService _service;
  final WalletService _walletService;
  final DFXAuthService _authService;
  Timer? _checkForTimer;
  Future<BitboxConnectionStatus>? _pendingInit;
  StreamSubscription<BitboxConnectionStatus>? _statusSub;

  /// Routes service-level transitions into the cubit's UX state machine. The
  /// only mid-flow transition the cubit cares about is `Lost` — the
  /// service-level signal that the paired device is gone before the cubit
  /// has reached `BitboxConnected` is the channel the timeout / observer
  /// paths feed (see `_synchronizeBoundedSign` propagation in
  /// `BitboxCredentials` and the periodic observer in `BitboxService`).
  void _onServiceStatus(BitboxConnectionStatus status) {
    if (isClosed) return;
    if (status is Lost) {
      developer.log('service emitted Lost(${status.reason.name})',
          name: '$ConnectBitboxCubit');
      _pendingInit = null;
      _checkForTimer?.cancel();
      emit(BitboxNotConnected());
      _checkForTimer = Timer.periodic(
        const Duration(milliseconds: 500),
        (_) => checkForBitbox(),
      );
    }
  }

  Future<void> checkForBitbox() async {
    final devices = await _service.getAllUsbDevices();
    if (isClosed) return;
    if (devices.isNotEmpty) {
      emit(BitboxFound(devices.first));
      _checkForTimer?.cancel();
      connectToBitbox(devices.first);
    }
  }

  Future<void> connectToBitbox(sdk.BitboxDevice device) async {
    if (state is BitboxConnecting) return;
    emit(BitboxConnecting(device));
    try {
      // Snapshot any hash from a prior pairing on the same BitboxService
      // instance so polling waits for the new session's hash instead of
      // accepting a stale value from an earlier pairing.
      String? priorHash;
      try {
        priorHash = await _service.getChannelHash().timeout(const Duration(seconds: 2));
      } catch (_) {
        // no prior session
      }
      if (isClosed) return;

      var initFailed = false;
      _pendingInit = _service.init(device).then((status) {
        if (status is! Paired && status is! InUse) initFailed = true;
        return status;
      }).catchError((Object e) {
        developer.log('init error: $e', name: '$ConnectBitboxCubit');
        initFailed = true;
        return const Disconnected() as BitboxConnectionStatus;
      });

      String channelHash = '';
      final deadline = DateTime.now().add(const Duration(seconds: 90));
      var firstIteration = true;
      while (channelHash.isEmpty && DateTime.now().isBefore(deadline) && !isClosed) {
        // First sleep is longer so the SDK can finish setting up its Go-side
        // device pointer before we call into it; subsequent iterations stay
        // tight so the post-PIN handover feels snappy.
        await Future.delayed(
          firstIteration ? const Duration(milliseconds: 500) : const Duration(milliseconds: 100),
        );
        firstIteration = false;
        if (isClosed) return;
        if (initFailed) throw Exception('init failed');
        try {
          final hash = await _service.getChannelHash().timeout(const Duration(seconds: 2));
          if (hash.isNotEmpty && hash != priorHash) channelHash = hash;
        } catch (_) {}
      }

      if (isClosed) return;

      if (channelHash.isEmpty) throw TimeoutException('no channel hash within 90s');

      emit(BitboxCheckHash(device, channelHash));
    } catch (e) {
      developer.log(e.toString(), name: '$ConnectBitboxCubit');
      _pendingInit = null;
      if (isClosed) return;
      emit(BitboxNotConnected());
      _checkForTimer = Timer.periodic(const Duration(milliseconds: 500), (_) => checkForBitbox());
    }
  }

  Future<void> confirmPairing() async {
    final currentState = state;
    if (currentState is! BitboxCheckHash) return;

    try {
      emit(BitboxPairing(currentState.device));
      // _pendingInit now resolves to a BitboxConnectionStatus — only Paired
      // (or the transient InUse) counts as a successful init. Anything else
      // (Connecting still pending, Disconnected, Lost, Disconnecting) means
      // the device-side confirmation never landed and the cubit must bounce
      // back to BitboxNotConnected.
      final initStatus = await _pendingInit!.timeout(
        _pairingPinTimeout,
        onTimeout: () => const Disconnected() as BitboxConnectionStatus,
      );
      if (initStatus is! Paired && initStatus is! InUse) {
        throw Exception('pairing not confirmed on device');
      }
      await _service.confirmPairing().timeout(
        _confirmPairingTimeout,
        onTimeout: () => throw TimeoutException(
          'BitBox did not acknowledge channel-hash verify within '
          '${_confirmPairingTimeout.inSeconds}s — BLE link likely silent. '
          'Disconnect the device, restart the app, and re-pair.',
        ),
      );
      final wallet = await _walletService
          .createBitboxWallet('Luke-Skywallet')
          .timeout(
            _createWalletTimeout,
            onTimeout: () => throw TimeoutException(
              'BitBox did not return an ETH address within '
              '${_createWalletTimeout.inSeconds}s. Try disconnecting and re-pairing.',
            ),
          );
      _service.startConnectionStatusObserver();
      await _captureAuthSignature(wallet);
    } catch (e) {
      developer.log(e.toString(), name: '$ConnectBitboxCubit');
      _pendingInit = null;
      if (isClosed) return;
      emit(BitboxNotConnected());
      _checkForTimer = Timer.periodic(const Duration(milliseconds: 500), (_) => checkForBitbox());
    }
  }

  /// Captures and caches the auth signature as an awaited, user-guided step of
  /// the pairing flow. The BitBox is guaranteed connected here, so every later
  /// buy / KYC / user-data call can run off the cached signature without
  /// re-engaging the device. A failure surfaces as [BitboxSignatureFailed] with
  /// its own retry / continue path instead of being swallowed — never rethrows,
  /// so `confirmPairing`'s outer catch is unaffected.
  Future<void> _captureAuthSignature(BitboxWallet wallet) async {
    if (isClosed) return;
    emit(BitboxCapturingSignature(wallet));
    try {
      await _authService.ensureSignatureFor(wallet.currentAccount);
      if (isClosed) return;
      emit(BitboxConnected(wallet));
    } catch (e) {
      developer.log(
        'auth signature capture failed: $e',
        name: '$ConnectBitboxCubit',
      );
      if (isClosed) return;
      emit(BitboxSignatureFailed(wallet));
    }
  }

  /// Re-runs the signature capture after a [BitboxSignatureFailed].
  Future<void> retrySignatureCapture() async {
    final currentState = state;
    if (currentState is! BitboxSignatureFailed) return;
    await _captureAuthSignature(currentState.wallet);
  }

  /// Skips the signature capture after a [BitboxSignatureFailed]. The lazy path
  /// in `DFXAuthService.getSignature` still recovers on the next authenticated
  /// call — the UI warns but never hard-blocks the user.
  void continueWithoutSignature() {
    final currentState = state;
    if (currentState is! BitboxSignatureFailed) return;
    if (isClosed) return;
    emit(BitboxConnected(currentState.wallet));
  }

  void finishSetup() {
    final currentState = state;
    if (currentState is! BitboxConnected) return;
    emit(BitboxFinishSetup(currentState.wallet));
  }

  @override
  Future<void> close() {
    _checkForTimer?.cancel();
    // Detach from the in-flight init future so any late error doesn't surface
    // as an unhandled exception after the cubit is gone.
    _pendingInit?.ignore();
    _pendingInit = null;
    // Cancel the lifecycle subscription so the broadcast Stream stops
    // holding a reference to this cubit (prevents subscription-leak; pinned
    // by the "cancelled subscriptions stop receiving transitions" test in
    // bitbox_service_lifecycle_test.dart). The await is fire-and-forget
    // chained off super.close() so a hot-restart with many cubits doesn't
    // serialise on the cancellation.
    final sub = _statusSub;
    _statusSub = null;
    sub?.cancel();
    return super.close();
  }
}
