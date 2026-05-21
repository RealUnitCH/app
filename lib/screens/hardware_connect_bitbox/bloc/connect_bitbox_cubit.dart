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
      // Fire-and-forget the auth-signature capture. Once persisted, every
      // later buy / KYC / user-data call runs off the cached signature without
      // needing the hardware wallet present. Awaiting would block the pairing
      // UI for the EIP-191 BitBox confirmation + the 20 s HTTP timeout; if it
      // fails the lazy path in DFXAuthService.getSignature still recovers.
      unawaited(
        warmAuthSignature(
          _authService,
          wallet.currentAccount,
          loggerName: '$ConnectBitboxCubit',
        ),
      );
      emit(BitboxConnected(wallet));
    } catch (e) {
      developer.log(e.toString(), name: '$ConnectBitboxCubit');
      _pendingInit = null;
      if (isClosed) return;
      emit(BitboxNotConnected());
      _checkForTimer = Timer.periodic(const Duration(milliseconds: 500), (_) => checkForBitbox());
    }
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
