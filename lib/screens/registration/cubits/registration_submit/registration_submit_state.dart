part of 'registration_submit_cubit.dart';

abstract class RegistrationSubmitState extends Equatable {
  const RegistrationSubmitState();

  @override
  List<Object?> get props => [];
}

class RegistrationSubmitInitial extends RegistrationSubmitState {}

class RegistrationSubmitLoading extends RegistrationSubmitState {}

class RegistrationSubmitSuccess extends RegistrationSubmitState {
  final RegistrationStatus status;

  const RegistrationSubmitSuccess(this.status);

  @override
  List<Object?> get props => [status];
}

class RegistrationSubmitFailure extends RegistrationSubmitState {
  final String message;

  const RegistrationSubmitFailure(this.message);

  @override
  List<Object?> get props => [message];
}
