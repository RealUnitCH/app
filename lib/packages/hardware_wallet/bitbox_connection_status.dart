import 'package:bitbox_flutter/bitbox_flutter.dart';
import 'package:equatable/equatable.dart';

/// Reasons the connection transitioned to [Lost].
///
/// Each value names a distinct trust-boundary event so the consumer can decide
/// whether to silently re-pair, show the reconnect sheet, or refuse to sign
/// without a fresh channel hash. The set is closed by design — adding a new
/// value is a deliberate API extension and forces an exhaustiveness review at
/// every switch site.
enum LostReason {
  /// `_synchronizeBoundedSign` fired its `signQueueTimeout`. The native sign
  /// is still in flight against the (now-desynced) noise cipher; the next
  /// sign would either decrypt garbage or hang. The recovery is a full
  /// re-pair so the host obtains a fresh ephemeral noise channel.
  signQueueTimeout,

  /// The observer compared the currently-paired device's static pubkey with
  /// the device-list entry's pubkey and found a mismatch. Either the user
  /// swapped a different BitBox in, or the device was factory-reset and a
  /// new static pubkey was generated. Either case requires explicit
  /// re-pairing rather than silent reconnect.
  staticPubkeyMismatch,

  /// The user (or a higher-level lifecycle hook) explicitly asked the
  /// service to drop the pairing — e.g. `_onDeleteCurrentWallet` invoking
  /// `BitboxService.clear()` while a session is live.
  manualDisconnect,

  /// The periodic observer's `getDevices()` probe returned an empty list and
  /// the host-side transport was torn down. The device is physically gone
  /// (unplugged, BLE link silent, USB FD released).
  deviceUnreachable,

  /// Co-design with Initiative III simulator scenarios — the device was
  /// detected to have been factory-reset between sessions (new static
  /// pubkey on second connect). Distinct from [staticPubkeyMismatch] only
  /// in observability semantics; both refuse silent reconnect.
  factoryResetDetected,
}

/// Sealed view of the BitBox connection lifecycle owned by `BitboxService`.
///
/// State-machine traversal (see ADR 0001):
///
/// ```
/// Disconnected → Connecting → Paired → InUse → Lost → Disconnecting → Disconnected
/// ```
///
/// All variants are immutable and use value equality so identical states can
/// be deduplicated by the broadcast controller and asserted on with
/// `equals(...)` instead of `same(...)`.
sealed class BitboxConnectionStatus extends Equatable {
  const BitboxConnectionStatus();
}

/// No device is paired. Initial state at service construction; terminal
/// state after [Disconnecting] resolves.
final class Disconnected extends BitboxConnectionStatus {
  const Disconnected();

  @override
  List<Object?> get props => const <Object?>[];

  @override
  String toString() => 'Disconnected()';
}

/// A connect is in flight. The service is awaiting `bitboxManager.connect()`
/// + `initBitBox()`. The user has NOT yet seen a channel hash.
final class Connecting extends BitboxConnectionStatus {
  const Connecting(this.device);

  final BitboxDevice device;

  @override
  List<Object?> get props => <Object?>[device.identifier];

  @override
  String toString() => 'Connecting(${device.identifier})';
}

/// Pairing complete; credentials are attached; the channel hash has been
/// verified by the user. No sign is currently in flight.
final class Paired extends BitboxConnectionStatus {
  const Paired(this.device);

  final BitboxDevice device;

  @override
  List<Object?> get props => <Object?>[device.identifier];

  @override
  String toString() => 'Paired(${device.identifier})';
}

/// A sign-shaped operation is in flight against the paired device. Distinct
/// from [Paired] so a UI layer can choose a different "busy" affordance and
/// so observers can pin "InUse only ever follows Paired" as an invariant.
final class InUse extends BitboxConnectionStatus {
  const InUse(this.device, this.context);

  final BitboxDevice device;
  final SignContext context;

  @override
  List<Object?> get props => <Object?>[device.identifier, context];

  @override
  String toString() => 'InUse(${device.identifier}, $context)';
}

/// The pairing was lost mid-session. Terminal for this pairing — the
/// consumer must call `clear()` to transition to [Disconnecting] and then
/// [Disconnected] before another `init()` can succeed.
final class Lost extends BitboxConnectionStatus {
  const Lost(this.reason);

  final LostReason reason;

  @override
  List<Object?> get props => <Object?>[reason];

  @override
  String toString() => 'Lost(${reason.name})';
}

/// Disconnect is in flight — `bitboxManager.disconnect()` is awaiting. The
/// service may briefly stay in this state on Android where releasing the USB
/// FD takes a few ms. From here the only legal next state is [Disconnected].
final class Disconnecting extends BitboxConnectionStatus {
  const Disconnecting();

  @override
  List<Object?> get props => const <Object?>[];

  @override
  String toString() => 'Disconnecting()';
}

/// Describes which sign operation is currently in flight on the device.
///
/// Carried inside [InUse] so future Tier-1 / Tier-2 tests can assert "we
/// only ever signed payload X exactly once" without depending on cubit-level
/// state shape. Initiative II's `SignPipeline` will own the canonical
/// construction of these.
class SignContext extends Equatable {
  const SignContext({
    required this.address,
    required this.derivationPath,
    required this.kind,
  });

  /// EIP-55-or-lowercase hex address of the credentials handling the sign.
  final String address;

  /// BIP-32 derivation path the sign is performed against.
  final String derivationPath;

  /// Discriminator for the sign shape. Kept open as a String so Initiative
  /// II can extend it (`eip712`, `eip7702`, `btcPsbt`, `personalMessage`,
  /// `rlpTransaction`, ...) without forcing a coordinated change here.
  final String kind;

  @override
  List<Object?> get props => <Object?>[address, derivationPath, kind];

  @override
  String toString() => 'SignContext($kind on $address @ $derivationPath)';
}
