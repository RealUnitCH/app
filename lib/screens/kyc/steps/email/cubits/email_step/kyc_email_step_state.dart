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

/// The API has sent a code to [email] and stores the address only once that
/// code is confirmed (register/email returned `verification_code_sent`). The
/// view routes to the code entry page.
class KycEmailStepCodeSent extends KycEmailStepState {
  final String email;

  const KycEmailStepCodeSent(this.email);

  @override
  List<Object?> get props => [email];
}

enum KycEmailStepError { emailDoesNotMatch, timeout, unknown }

class KycEmailStepFailure extends KycEmailStepState {
  final KycEmailStepError error;
  final String message;

  const KycEmailStepFailure(this.error, this.message);

  @override
  List<Object?> get props => [error, message];
}
