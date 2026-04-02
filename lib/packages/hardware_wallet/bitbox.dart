import 'package:bitbox_flutter/bitbox_flutter.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_credentials.dart';

class BitboxService {
  final BitboxManager bitboxManager = BitboxManager();
  bool _isConnected = false;

  Future<List<BitboxDevice>> getAllUsbDevices() => bitboxManager.devices;

  Future<bool> startScan() => bitboxManager.startScan();

  BitboxCredentials getCredentials(String address) {
    final credentials = BitboxCredentials(address);
    if (_isConnected) credentials.setBitbox(bitboxManager);
    return credentials;
  }

  Future<bool> init(BitboxDevice device) async {
    await bitboxManager.connect(device);
    final didInit = await bitboxManager.initBitBox();
    if (!didInit) throw Exception('Failed to init');
    _isConnected = true;
    return didInit;
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
