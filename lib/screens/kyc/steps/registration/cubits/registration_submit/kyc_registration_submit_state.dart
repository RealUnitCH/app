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

  const KycRegistrationSubmitFailure(this.message);

  @override
  List<Object?> get props => [message];
}
