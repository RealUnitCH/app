import 'dart:async';
import 'dart:developer' as developer;

import 'package:bitbox_flutter/bitbox_flutter.dart' as sdk;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
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

  // The bitbox02 firmware status for a device that has no wallet set up — it
  // cannot derive an address. Mirrors the SDK's `StatusUninitialized`. Only this
  // value is treated as "not set up": other non-ready statuses (e.g. a firmware
  // upgrade requirement) are intentionally left on the existing failure path
  // rather than mislabelled as unseeded.
  static const _statusUninitialized = 'uninitialized';

  // The status read is a local cached lookup (no device round-trip), so it
  // returns in milliseconds. This cap only exists so a hypothetical stall can
  // never hang the pairing flow — on timeout the read is treated as "not
  // uninitialized" (fail-open) and the normal acquire path proceeds.
  static const Duration _deviceStatusTimeout = Duration(seconds: 5);

  ConnectBitboxCubit(
    this._service,
    this._walletService,
    this._authService, {
    Duration confirmPairingTimeout = _defaultConfirmPairingTimeout,
    Duration createWalletTimeout = _defaultCreateWalletTimeout,
    Duration pairingPinTimeout = _defaultPairingPinTimeout,
    Future<BitboxWallet> Function()? acquireWallet,
  }) : _confirmPairingTimeout = confirmPairingTimeout,
       _createWalletTimeout = createWalletTimeout,
       _pairingPinTimeout = pairingPinTimeout,
       _acquireWallet = acquireWallet,
       super(BitboxNotConnected()) {
    _startScanning();
  }

  final Duration _confirmPairingTimeout;
  final Duration _createWalletTimeout;
  final Duration _pairingPinTimeout;

  /// Injectable wallet-acquisition step. `null` selects the default behaviour:
  /// the initial-pairing flow creates a brand-new view wallet. The
  /// address-recovery flow passes [WalletService.healCurrentBitboxAddress] so
  /// the same pairing ceremony backfills the empty address onto the existing
  /// row instead of creating a second wallet.
  final Future<BitboxWallet> Function()? _acquireWallet;

  Future<BitboxWallet> _acquireWalletOrDefault() =>
      (_acquireWallet ?? (() => _walletService.createBitboxWallet('Luke-Skywallet')))();

  Future<void> _startScanning() async {
    if (DeviceInfo.instance.isIOS) await _service.startScan();
    _checkForTimer = Timer.periodic(const Duration(milliseconds: 500), (_) => checkForBitbox());
  }

  final BitboxService _service;
  final WalletService _walletService;
  final DFXAuthService _authService;
  Timer? _checkForTimer;
  Future<bool>? _pendingInit;

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
    // Coalesce overlapping scan ticks onto ONE connect attempt: the state
    // guard alone is defeated once the flow moves past BitboxConnecting
    // (e.g. BitboxCheckHash) while the init future is still pending — a late
    // tick then started a second init() on the shared SDK manager and wedged
    // pairing (issue #657 P7 F1). `_pendingInit` covers that whole window; it
    // is cleared on failure, so a genuine retry still passes.
    if (state is BitboxConnecting || _pendingInit != null) return;
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
      _pendingInit = _service
          .init(device)
          .then((success) {
            if (!success) initFailed = true;
            return success;
          })
          .catchError((Object e) {
            developer.log('init error: $e', name: '$ConnectBitboxCubit');
            initFailed = true;
            return false;
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
      final initOk = await _pendingInit!.timeout(
        _pairingPinTimeout,
        onTimeout: () => false,
      );
      if (!initOk) throw Exception('pairing not confirmed on device');
      await _service.confirmPairing().timeout(
        _confirmPairingTimeout,
        onTimeout: () => throw TimeoutException(
          'BitBox did not acknowledge channel-hash verify within '
          '${_confirmPairingTimeout.inSeconds}s — BLE link likely silent. '
          'Disconnect the device, restart the app, and re-pair.',
        ),
      );
      // A device paired without a wallet set up has no seed, so the address read
      // below would come back empty and fail as a generic error — bouncing the
      // user into the silent re-scan loop with no idea why. Detect it up front
      // and surface a dedicated state. Returning here (instead of throwing) means
      // no re-scan timer is armed, so the device isn't picked up and re-paired in
      // an endless loop.
      if (await _isDeviceUninitialized()) {
        if (isClosed) return;
        emit(BitboxNotInitialized(currentState.device));
        return;
      }
      await _acquireWalletAndConnect();
    } catch (e) {
      developer.log(e.toString(), name: '$ConnectBitboxCubit');
      _pendingInit = null;
      if (isClosed) return;
      emit(BitboxNotConnected());
      _checkForTimer = Timer.periodic(const Duration(milliseconds: 500), (_) => checkForBitbox());
    }
  }

  /// Reads the device status, treating ONLY a clean, explicit `uninitialized`
  /// read as "no wallet set up". Any failure or unexpected value returns false
  /// (fail-open), so a status read can never block a device that would otherwise
  /// pair successfully — it only ever adds the dedicated unseeded path on top of
  /// the existing behaviour, never removes the working one.
  Future<bool> _isDeviceUninitialized() async {
    try {
      final status = await _service.getDeviceStatus().timeout(_deviceStatusTimeout);
      return status == _statusUninitialized;
    } catch (e) {
      developer.log(
        'device status read failed/timed out, treating device as ready: $e',
        name: '$ConnectBitboxCubit',
      );
      return false;
    }
  }

  /// Acquires the wallet from the device and finishes the connection. Shared by
  /// the initial pairing flow and the [recheckDeviceStatus] retry so both run
  /// the same create/observe/sign sequence.
  Future<void> _acquireWalletAndConnect() async {
    final wallet = await _acquireWalletOrDefault().timeout(
      _createWalletTimeout,
      onTimeout: () => throw TimeoutException(
        'BitBox did not return an ETH address within '
        '${_createWalletTimeout.inSeconds}s. Try disconnecting and re-pairing.',
      ),
    );
    _service.startConnectionStatusObserver();
    await _captureAuthSignature(wallet);
  }

  /// Re-reads the device status after a [BitboxNotInitialized], for when the user
  /// has set up / restored a wallet on the device and wants to continue without
  /// re-pairing. If the device now reports a wallet, the connection proceeds; if
  /// it is still unseeded, the state is re-emitted so the user can try again.
  Future<void> recheckDeviceStatus() async {
    final currentState = state;
    if (currentState is! BitboxNotInitialized) return;
    try {
      if (await _isDeviceUninitialized()) {
        if (isClosed) return;
        emit(BitboxNotInitialized(currentState.device));
        return;
      }
      if (isClosed) return;
      emit(BitboxPairing(currentState.device));
      await _acquireWalletAndConnect();
    } catch (e) {
      developer.log(e.toString(), name: '$ConnectBitboxCubit');
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
    return super.close();
  }
}
