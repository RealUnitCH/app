import 'package:realunit_wallet/packages/hardware_wallet/bitbox_credentials.dart';

class BitboxNotConnectedException implements Exception {
  final BitboxCredentials credentials;

  const BitboxNotConnectedException(this.credentials);
}
