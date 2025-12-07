import 'dart:async';

import 'package:bitbox_flutter/bitbox_flutter.dart' as sdk;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

class ConnectBitboxCubit extends Cubit<BitboxConnectionState> {
  ConnectBitboxCubit(this._service, this._walletService)
      : super(BitboxNotConnected()) {
    _checkForTimer =
        Timer.periodic(Duration(milliseconds: 50), (_) => checkForBitbox());
  }

  final BitboxService _service;
  final WalletService _walletService;
  Timer? _checkForTimer;
  bool _isConnecting = false;

  Future<void> checkForBitbox() async {
    final devices = await _service.getAllUsbDevices();
    print(devices);
    if (devices.isNotEmpty) {
      emit(BitboxFound(devices.first));
      _checkForTimer?.cancel();
      connectToBitbox(devices.first);
    }
  }

  Future<void> connectToBitbox(sdk.BitboxDevice device) async {
    if (_isConnecting) return;
    _isConnecting = true;
    try {
      await _service.connectDevice(device);
      final wallet = await _walletService.createBitboxWallet("Luke-Skywallet");
      emit(BitboxConnected(wallet));
    } catch (_) {
      emit(BitboxNotConnected());
      _checkForTimer =
          Timer.periodic(Duration(milliseconds: 30), (_) => checkForBitbox());
    }
    _isConnecting = false;
  }

  @override
  Future<void> close() async {
    _checkForTimer?.cancel();
    super.close();
  }
}

abstract class BitboxConnectionState {}

class BitboxNotConnected extends BitboxConnectionState {}

class BitboxFound extends BitboxConnectionState {
  final sdk.BitboxDevice device;

  BitboxFound(this.device);
}

class BitboxConnected extends BitboxConnectionState {
  final BitboxWallet wallet;

  BitboxConnected(this.wallet);
}
