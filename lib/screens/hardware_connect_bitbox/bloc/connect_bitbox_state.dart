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

class BitboxCheckHash extends BitboxFound {
  final String channelHash;

  BitboxCheckHash(super.device, this.channelHash);
}

class BitboxPairing extends BitboxFound {
  BitboxPairing(super.device);
}

/// The paired BitBox has no wallet set up yet (firmware status `uninitialized`),
/// so no address can be derived. A dedicated state — not the generic failure —
/// so the UI can tell the user to set up / restore a wallet on the device first,
/// instead of bouncing through the silent re-scan loop. Carries the device so a
/// re-check can continue the connection without re-pairing.
class BitboxNotInitialized extends BitboxFound {
  BitboxNotInitialized(super.device);
}

class BitboxCapturingSignature extends BitboxConnectionState {
  final BitboxWallet wallet;

  BitboxCapturingSignature(this.wallet);
}

class BitboxSignatureFailed extends BitboxConnectionState {
  final BitboxWallet wallet;

  BitboxSignatureFailed(this.wallet);
}

class BitboxConnected extends BitboxConnectionState {
  final BitboxWallet wallet;

  BitboxConnected(this.wallet);
}

class BitboxFinishSetup extends BitboxConnectionState {
  final BitboxWallet wallet;

  BitboxFinishSetup(this.wallet);
}
