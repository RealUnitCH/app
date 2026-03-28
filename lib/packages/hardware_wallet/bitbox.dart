import 'package:bitbox_flutter/bitbox_flutter.dart' as sdk;
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_credentials.dart';

class BitboxService {
  BitboxService() {
    bitboxManager = sdk.BitboxManager();
  }

  late sdk.BitboxManager bitboxManager;

  Future<List<sdk.BitboxDevice>> getAllUsbDevices() => bitboxManager.devices;

  Future<bool> startScan() => bitboxManager.startScan();

  BitboxCredentials getCredentials(String address) =>
      BitboxCredentials(address)..setBitbox(bitboxManager);

  /// Step 1: Connect and initialize - returns channel hash for pairing
  Future<String> connectAndInit(sdk.BitboxDevice device) async {
    await bitboxManager.connect(device);
    final didInit = await bitboxManager.initBitBox();

    if (!didInit) throw Exception('Failed to init');

    // Get the channel hash - this is shown on the BitBox device
    // The user must verify it matches before confirming
    final hash = await bitboxManager.getChannelHash();
    return hash;
  }

  /// Step 2: Confirm pairing after user verified on BitBox device
  Future<void> confirmPairing() async {
    final didVerify = await bitboxManager.channelHashVerify();
    if (!didVerify) throw Exception('Failed to verify');
  }

  /// Legacy method - connects and immediately verifies (requires user to confirm on device first)
  Future<void> connectDevice(sdk.BitboxDevice device) async {
    await connectAndInit(device);
    await confirmPairing();
  }
}
