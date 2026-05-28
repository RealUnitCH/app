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

/// Terminal state when the prefill payload is missing required fields
/// (≤19-account edge case with partial DFX KYC data). The user has to fix the
/// underlying profile via a separate flow — no retry from this page.
class KycRegisterProfileIncomplete extends KycRegisterState {
  const KycRegisterProfileIncomplete();
}
