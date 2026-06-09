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

class KycEmailVerificationMergeProcessing extends KycEmailVerificationState {
  const KycEmailVerificationMergeProcessing();
}
