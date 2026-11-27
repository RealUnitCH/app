part of 'kyc_email_code_cubit.dart';

abstract class KycEmailCodeState extends Equatable {
  const KycEmailCodeState();

  @override
  List<Object?> get props => [];
}

class KycEmailCodeInitial extends KycEmailCodeState {
  const KycEmailCodeInitial();
}

/// The entered code is being confirmed, followed by the second
/// `register/email` call.
class KycEmailCodeVerifying extends KycEmailCodeState {
  const KycEmailCodeVerifying();
}

/// A new code is being requested by calling `register/email` again.
class KycEmailCodeResending extends KycEmailCodeState {
  const KycEmailCodeResending();
}

/// The API has sent a new code to the address.
class KycEmailCodeResent extends KycEmailCodeState {
  const KycEmailCodeResent();
}

/// The email step is finished with the [status] the API returned. The view
/// pops with it, so the caller handles it like a direct `register/email`
/// answer.
class KycEmailCodeCompleted extends KycEmailCodeState {
  final RegistrationEmailStatus status;

  const KycEmailCodeCompleted(this.status);

  @override
  List<Object?> get props => [status];
}

enum KycEmailCodeError { invalidCode, unknown }

class KycEmailCodeFailure extends KycEmailCodeState {
  final KycEmailCodeError error;

  const KycEmailCodeFailure(this.error);

  @override
  List<Object?> get props => [error];
}
