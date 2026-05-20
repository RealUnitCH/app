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
  // Keyed by EIP-55 address so multi-wallet (future) reconnect re-attaches
  // every active set of credentials, not just the most recently handed out.
  final Map<String, BitboxCredentials> _credentialsByAddress = {};
  Timer? _connectionStatusObserver;
  Future<void>? _pendingDisconnect;

  Future<List<BitboxDevice>> getAllUsbDevices() => bitboxManager.devices;

  Future<bool> startScan() => bitboxManager.startScan();

  BitboxCredentials getCredentials(String address) {
    final credentials = _credentialsByAddress.putIfAbsent(
      address,
      () => BitboxCredentials(address),
    );
    if (_isConnected) {
      credentials.setBitbox(bitboxManager);
    }
    return credentials;
  }

  Future<bool> init(BitboxDevice device) async {
    // The disconnect observer fires .disconnect() asynchronously when the
    // device drops. If the user re-plugs immediately we'd race two ops on the
    // same SDK manager and the result is undefined. Wait for any in-flight
    // disconnect to finish first.
    await _pendingDisconnect;
    await bitboxManager.connect(device);
    final didInit = await bitboxManager.initBitBox();
    if (!didInit) throw Exception('Failed to init');
    _isConnected = true;
    // Re-attach the manager to every active credentials instance so existing
    // wallets heal automatically on reconnect. The previous derivationPath is
    // preserved inside setBitbox().
    for (final credentials in _credentialsByAddress.values) {
      credentials.setBitbox(bitboxManager);
    }
    return didInit;
  }

  void startConnectionStatusObserver() {
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
        _isConnected = false;
        for (final credentials in _credentialsByAddress.values) {
          credentials.clearBitbox();
        }
        stopConnectionStatusObserver();
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
