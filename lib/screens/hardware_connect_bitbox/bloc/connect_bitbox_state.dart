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

class BitboxConnected extends BitboxConnectionState {
  final BitboxWallet wallet;

  BitboxConnected(this.wallet);
}
