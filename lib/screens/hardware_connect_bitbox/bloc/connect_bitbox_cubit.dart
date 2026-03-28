import 'dart:async';

import 'package:bitbox_flutter/bitbox_flutter.dart' as sdk;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

part 'connect_bitbox_state.dart';

class ConnectBitboxCubit extends Cubit<BitboxConnectionState> {
  ConnectBitboxCubit(this._service, this._walletService) : super(BitboxNotConnected()) {
    _startScanning();
  }

  Future<void> _startScanning() async {
    await _service.startScan();
    _checkForTimer = Timer.periodic(const Duration(milliseconds: 500), (_) => checkForBitbox());
  }

  final BitboxService _service;
  final WalletService _walletService;
  Timer? _checkForTimer;

  Future<void> checkForBitbox() async {
    final devices = await _service.getAllUsbDevices();
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
      // Step 1: Connect and get channel hash for pairing
      final channelHash = await _service.connectAndInit(device);
      emit(BitboxPairing(device, channelHash));
      // User must now confirm on BitBox device and tap confirm in app
    } catch (e) {
      // TODO: show error to user
      emit(BitboxNotConnected());
      _checkForTimer = Timer.periodic(const Duration(seconds: 2), (_) => checkForBitbox());
    }
  }

  /// Called when user confirms pairing in the app (after confirming on BitBox device)
  Future<void> confirmPairing() async {
    final currentState = state;
    if (currentState is! BitboxPairing) return;

    try {
      await _service.confirmPairing();
      final wallet = await _walletService.createBitboxWallet('Luke-Skywallet');
      emit(BitboxConnected(wallet));
    } catch (e) {
      // TODO: show error to user
      emit(BitboxNotConnected());
      _checkForTimer = Timer.periodic(const Duration(seconds: 2), (_) => checkForBitbox());
    }
  }

  @override
  Future<void> close() async {
    _checkForTimer?.cancel();
    super.close();
  }
}
