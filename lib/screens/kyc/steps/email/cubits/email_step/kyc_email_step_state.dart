part of 'kyc_email_step_cubit.dart';

abstract class KycEmailStepState extends Equatable {
  const KycEmailStepState();

  @override
  List<Object?> get props => [];
}

class KycEmailStepInitial extends KycEmailStepState {
  const KycEmailStepInitial();
}

class KycEmailStepLoading extends KycEmailStepState {
  const KycEmailStepLoading();
}

class KycEmailStepSuccess extends KycEmailStepState {
  final RegistrationEmailStatus status;

  const KycEmailStepSuccess(this.status);

  @override
  List<Object?> get props => [status];
}

enum KycEmailStepError { emailDoesNotMatch, unknown }

class KycEmailStepFailure extends KycEmailStepState {
  final KycEmailStepError error;
  final String message;

  const KycEmailStepFailure(this.error, this.message);

  @override
  List<Object?> get props => [error, message];
}
