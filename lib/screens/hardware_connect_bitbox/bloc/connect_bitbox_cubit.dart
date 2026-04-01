import 'dart:async';
import 'dart:developer' as developer;

import 'package:bitbox_flutter/bitbox_flutter.dart' as sdk;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/utils/device_info.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

part 'connect_bitbox_state.dart';

class ConnectBitboxCubit extends Cubit<BitboxConnectionState> {
  ConnectBitboxCubit(this._service, this._walletService) : super(BitboxNotConnected()) {
    _startScanning();
  }

  Future<void> _startScanning() async {
    if (DeviceInfo.instance.isIOS) await _service.startScan();
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
      await _service.init(device);
      final channelHash = await _service.getChannelHash();
      emit(BitboxCheckHash(device, channelHash));
    } catch (e) {
      developer.log(e.toString(), name: '$ConnectBitboxCubit');
      emit(BitboxNotConnected());
      _checkForTimer = Timer.periodic(const Duration(seconds: 2), (_) => checkForBitbox());
    }
  }

  Future<void> confirmPairing() async {
    final currentState = state;
    if (currentState is! BitboxCheckHash) return;

    try {
      emit(BitboxPairing(currentState.device));
      await _service.confirmPairing();
      final wallet = await _walletService.createBitboxWallet('Luke-Skywallet');
      emit(BitboxConnected(wallet));
    } catch (e) {
      developer.log(e.toString(), name: '$ConnectBitboxCubit');
      emit(BitboxNotConnected());
      _checkForTimer = Timer.periodic(const Duration(seconds: 2), (_) => checkForBitbox());
    }
  }

  void finishSetup() {
    final currentState = state;
    if (currentState is! BitboxConnected) return;
    emit(BitboxFinishSetup(currentState.wallet));
  }

  @override
  Future<void> close() async {
    _checkForTimer?.cancel();
    super.close();
  }
}
