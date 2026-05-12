part of 'kyc_registration_submit_cubit.dart';

abstract class KycRegistrationSubmitState extends Equatable {
  const KycRegistrationSubmitState();

  @override
  List<Object?> get props => [];
}

class KycRegistrationSubmitInitial extends KycRegistrationSubmitState {}

class KycRegistrationSubmitLoading extends KycRegistrationSubmitState {}

class KycRegistrationSubmitSuccess extends KycRegistrationSubmitState {
  final RegistrationStatus status;

  const KycRegistrationSubmitSuccess(this.status);

  @override
  List<Object?> get props => [status];
}

class KycRegistrationSubmitFailure extends KycRegistrationSubmitState {
  final String message;
  final Object? cause;

  const KycRegistrationSubmitFailure(this.message, {this.cause});

  @override
  List<Object?> get props => [message, cause];
}

class KycRegistrationSubmitBitboxRequired extends KycRegistrationSubmitState {
  final Registration registration;

  const KycRegistrationSubmitBitboxRequired({
    required this.registration,
  });

  @override
  List<Object?> get props => [registration];
}
