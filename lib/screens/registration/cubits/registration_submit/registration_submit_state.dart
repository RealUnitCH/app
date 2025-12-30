part of 'registration_submit_cubit.dart';

abstract class RegistrationSubmitState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RegistrationSubmitInitial extends RegistrationSubmitState {}

class RegistrationSubmitLoading extends RegistrationSubmitState {}

class RegistrationSubmitSuccess extends RegistrationSubmitState {
  final DfxRegistrationStatus status;

  RegistrationSubmitSuccess(this.status);

  @override
  List<Object?> get props => [status];
}

class RegistrationSubmitFailure extends RegistrationSubmitState {
  final String message;

  RegistrationSubmitFailure(this.message);

  @override
  List<Object?> get props => [message];
}
