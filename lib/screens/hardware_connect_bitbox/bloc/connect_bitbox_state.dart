part of 'connect_bitbox_cubit.dart';

abstract class BitboxConnectionState {}

class BitboxNotConnected extends BitboxConnectionState {}

class BitboxFound extends BitboxConnectionState {
  final sdk.BitboxDevice device;

  BitboxFound(this.device);
}

class BitboxConnecting extends BitboxFound {
  BitboxConnecting(super.device);
}

/// Pairing state - user needs to confirm the hash on the BitBox device
class BitboxPairing extends BitboxFound {
  final String channelHash;

  BitboxPairing(super.device, this.channelHash);
}

class BitboxConnected extends BitboxConnectionState {
  final BitboxWallet wallet;

  BitboxConnected(this.wallet);
}
