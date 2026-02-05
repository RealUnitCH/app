part of 'kyc_ident_cubit.dart';

abstract class KycIdentState extends Equatable {
  const KycIdentState();

  @override
  List<Object?> get props => [];
}

class KycIdentInitial extends KycIdentState {}

class KycIdentLoading extends KycIdentState {}

class KycIdentSuccess extends KycIdentState {}

class KycIdentFailure extends KycIdentState {
  final FailureStatus status;
  final String? errorMessage;

  const KycIdentFailure({required this.status, this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
