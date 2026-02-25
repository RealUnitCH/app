part of 'kyc_registration_email_verification_cubit.dart';

abstract class KycRegistrationEmailVerificationState extends Equatable {
  const KycRegistrationEmailVerificationState();

  @override
  List<Object?> get props => [];
}

class KycRegistrationEmailVerificationInitial extends KycRegistrationEmailVerificationState {
  const KycRegistrationEmailVerificationInitial();
}

class KycRegistrationEmailVerificationLoading extends KycRegistrationEmailVerificationState {
  const KycRegistrationEmailVerificationLoading();
}

class KycRegistrationEmailVerificationSuccess extends KycRegistrationEmailVerificationState {
  const KycRegistrationEmailVerificationSuccess();
}

class KycRegistrationEmailVerificationFailure extends KycRegistrationEmailVerificationState {
  const KycRegistrationEmailVerificationFailure();
}

class KycRegistrationEmailVerificationRegistrationFailure
    extends KycRegistrationEmailVerificationState {
  const KycRegistrationEmailVerificationRegistrationFailure();
}
