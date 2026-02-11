part of 'kyc_registration_email_step_cubit.dart';

abstract class KycRegistrationEmailStepState extends Equatable {
  const KycRegistrationEmailStepState();

  @override
  List<Object?> get props => [];
}

class KycRegistrationEmailStepInitial extends KycRegistrationEmailStepState {
  const KycRegistrationEmailStepInitial();
}

class KycRegistrationEmailStepLoading extends KycRegistrationEmailStepState {
  const KycRegistrationEmailStepLoading();
}

class KycRegistrationEmailStepSuccess extends KycRegistrationEmailStepState {
  final RegistrationEmailStatus status;

  const KycRegistrationEmailStepSuccess(this.status);

  @override
  List<Object?> get props => [status];
}

class KycRegistrationEmailStepFailure extends KycRegistrationEmailStepState {
  final String message;

  const KycRegistrationEmailStepFailure(this.message);

  @override
  List<Object?> get props => [message];
}
