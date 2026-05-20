import 'dart:async';
import 'dart:developer' as developer;

import 'package:bitbox_flutter/bitbox_flutter.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_credentials.dart';

class BitboxService {
  // Observer poll period is widened in production and tightened in tests so
  // device-loss-recovery behaviour can be exercised in real time without
  // five-second sleeps.
  BitboxService({Duration connectionStatusInterval = const Duration(seconds: 5)})
    : _connectionStatusInterval = connectionStatusInterval;

  final BitboxManager bitboxManager = BitboxManager();
  final Duration _connectionStatusInterval;
  bool _isConnected = false;
  BitboxCredentials? _credentials;
  Timer? _connectionStatusObserver;

  Future<List<BitboxDevice>> getAllUsbDevices() => bitboxManager.devices;

  Future<bool> startScan() => bitboxManager.startScan();

  BitboxCredentials getCredentials(String address) {
    final credentials = BitboxCredentials(address);
    _credentials = credentials;
    if (_isConnected) {
      credentials.setBitbox(bitboxManager);
    }
    return credentials;
  }

  Future<bool> init(BitboxDevice device) async {
    await bitboxManager.connect(device);
    final didInit = await bitboxManager.initBitBox();
    if (!didInit) throw Exception('Failed to init');
    _isConnected = true;
    // Restore the bitbox manager on any credentials handed out before this
    // (re-)connect — otherwise existing wallets keep a cleared credentials
    // instance and the next sign throws BitboxNotConnectedException even
    // though the device is back online.
    _credentials?.setBitbox(bitboxManager);
    return didInit;
  }

  void startConnectionStatusObserver() {
    _connectionStatusObserver?.cancel();
    _connectionStatusObserver = Timer.periodic(_connectionStatusInterval, (_) async {
      final devices = await getAllUsbDevices();
      if (devices.isEmpty) {
        _isConnected = false;
        _credentials?.clearBitbox();
        // Keep the _credentials reference so init() can re-attach the manager
        // on the same instance after a reconnect.
        stopConnectionStatusObserver();
        // Close the underlying transport. Required on Android so the USB
        // file-descriptor is released — otherwise the next connect() can
        // fail because the OS still considers the device claimed. Safe on
        // iOS where the BLE link is already gone at this point.
        try {
          await bitboxManager.disconnect();
        } catch (e) {
          developer.log('disconnect after device-loss failed: $e', name: '$BitboxService');
        }
      }
    });
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
