part of 'registration_email_verification_cubit.dart';

abstract class RegistrationEmailVerificationState extends Equatable {
  const RegistrationEmailVerificationState();

  @override
  List<Object?> get props => [];
}

class RegistrationEmailVerificationInitial extends RegistrationEmailVerificationState {
  const RegistrationEmailVerificationInitial();
}

class RegistrationEmailVerificationLoading extends RegistrationEmailVerificationState {
  const RegistrationEmailVerificationLoading();
}

class RegistrationEmailVerificationSuccess extends RegistrationEmailVerificationState {
  const RegistrationEmailVerificationSuccess();
}

class RegistrationEmailVerificationFailure extends RegistrationEmailVerificationState {
  const RegistrationEmailVerificationFailure();
}
