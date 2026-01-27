part of 'registration_email_verification_step_cubit.dart';

abstract class RegistrationEmailVerificationStepState extends Equatable {
  const RegistrationEmailVerificationStepState();

  @override
  List<Object?> get props => [];
}

class RegistrationEmailVerificationStepInitial extends RegistrationEmailVerificationStepState {}

class RegistrationEmailVerificationStepLoading extends RegistrationEmailVerificationStepState {}

class RegistrationEmailVerificationStepSuccess extends RegistrationEmailVerificationStepState {}

class RegistrationEmailVerificationStepFailure extends RegistrationEmailVerificationStepState {
  final String message;

  const RegistrationEmailVerificationStepFailure(this.message);

  @override
  List<Object?> get props => [message];
}
