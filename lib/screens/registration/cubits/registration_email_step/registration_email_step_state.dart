part of 'registration_email_step_cubit.dart';

abstract class RegistrationEmailStepState extends Equatable {
  const RegistrationEmailStepState();

  @override
  List<Object?> get props => [];
}

class RegistrationEmailStepInitial extends RegistrationEmailStepState {
  const RegistrationEmailStepInitial();
}

class RegistrationEmailStepLoading extends RegistrationEmailStepState {
  const RegistrationEmailStepLoading();
}

class RegistrationEmailStepSuccess extends RegistrationEmailStepState {
  final RegistrationEmailStatus status;

  const RegistrationEmailStepSuccess(this.status);

  @override
  List<Object?> get props => [status];
}

class RegistrationEmailStepFailure extends RegistrationEmailStepState {
  final String message;

  const RegistrationEmailStepFailure(this.message);

  @override
  List<Object?> get props => [message];
}
