import 'package:bitbox_flutter/bitbox_flutter.dart' as sdk;
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_credentials.dart';

class BitboxService {
  BitboxService() {
    bitboxManager = sdk.BitboxManager();
  }

  late sdk.BitboxManager bitboxManager;

  Future<List<sdk.BitboxDevice>> getAllUsbDevices() => bitboxManager.devices;

  BitboxCredentials getCredentials(String address) =>
      BitboxCredentials(address)..setBitbox(bitboxManager);

  Future<void> connectDevice(sdk.BitboxDevice device) async {
    await bitboxManager.connect(device);
    final didInit = await bitboxManager.initBitBox();

    if (!didInit) throw Exception("Failed to init");

    final didVerify = await bitboxManager.channelHashVerify();

    if (!didVerify) throw Exception("Failed to verify");
  }
}
