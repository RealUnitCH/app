part of 'kyc_register_cubit.dart';

abstract class KycRegisterState extends Equatable {
  const KycRegisterState();

  @override
  List<Object?> get props => [];
}

class KycRegisterReady extends KycRegisterState {
  final RealUnitUserDataDto userData;

  const KycRegisterReady(this.userData);

  @override
  List<Object?> get props => [userData];
}

class KycRegisterSubmitting extends KycRegisterState {
  final RealUnitUserDataDto userData;

  const KycRegisterSubmitting(this.userData);

  @override
  List<Object?> get props => [userData];
}

class KycRegisterSuccess extends KycRegisterState {
  const KycRegisterSuccess();
}

class KycRegisterFailure extends KycRegisterState {
  final String message;
  final Object? cause;

  const KycRegisterFailure(this.message, {this.cause});

  @override
  List<Object?> get props => [message, cause];
}

/// Recoverable failure-class signal emitted when the BitBox went away
/// mid-ceremony (e.g. a BLE link drop while building the EIP-712 signature).
/// The page reacts by surfacing the reconnect sheet and, on a successful
/// re-pair, retries `submit(userData)` — rather than collapsing into a
/// SnackBar that forces the user to restart the one-time registration.
class KycRegisterBitboxRequired extends KycRegisterState {
  final RealUnitUserDataDto userData;

  const KycRegisterBitboxRequired(this.userData);

  @override
  List<Object?> get props => [userData];
}

/// Terminal state when the prefill payload is missing required fields
/// (≤19-account edge case with partial DFX KYC data). The user has to fix the
/// underlying profile via a separate flow — no retry from this page.
class KycRegisterProfileIncomplete extends KycRegisterState {
  const KycRegisterProfileIncomplete();
}
