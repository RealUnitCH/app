part of 'kyc_email_verification_cubit.dart';

abstract class KycEmailVerificationState extends Equatable {
  const KycEmailVerificationState();

  @override
  List<Object?> get props => [];
}

class KycEmailVerificationInitial extends KycEmailVerificationState {
  const KycEmailVerificationInitial();
}

class KycEmailVerificationLoading extends KycEmailVerificationState {
  const KycEmailVerificationLoading();
}

class KycEmailVerificationSuccess extends KycEmailVerificationState {
  const KycEmailVerificationSuccess();
}

class KycEmailVerificationFailure extends KycEmailVerificationState {
  const KycEmailVerificationFailure();
}

class KycEmailVerificationRegistrationFailure
    extends KycEmailVerificationState {
  const KycEmailVerificationRegistrationFailure();
}

/// Emitted when the registerWallet sign threw
/// [BitboxNotConnectedException] mid-ceremony — closes BL-006. The page
/// listener routes this state to [showBitboxReconnectSheet]; on a
/// successful reconnect the cubit re-runs [checkEmailVerification]
/// (with the merge latch reset so the auth-side JWT account check runs
/// again).
class KycEmailVerificationBitboxRequired extends KycEmailVerificationState {
  const KycEmailVerificationBitboxRequired();
}
