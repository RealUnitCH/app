part of 'registration_email_verification_step_cubit.dart';

abstract class RegistrationEmailVerificationStepState extends Equatable {
  const RegistrationEmailVerificationStepState();

  @override
  List<Object?> get props => [];
}

class RegistrationEmailVerificationStepInitial extends RegistrationEmailVerificationStepState {
  const RegistrationEmailVerificationStepInitial();
}

class RegistrationEmailVerificationStepLoading extends RegistrationEmailVerificationStepState {
  const RegistrationEmailVerificationStepLoading();
}

class RegistrationEmailVerificationStepSuccess extends RegistrationEmailVerificationStepState {
  const RegistrationEmailVerificationStepSuccess();
}

class RegistrationEmailVerificationStepFailure extends RegistrationEmailVerificationStepState {
  const RegistrationEmailVerificationStepFailure();
}
