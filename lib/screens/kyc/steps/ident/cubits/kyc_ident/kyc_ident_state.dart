part of 'kyc_ident_cubit.dart';

abstract class KycIdentState extends Equatable {
  const KycIdentState();

  @override
  List<Object?> get props => [];
}

class KycIdentInitial extends KycIdentState {
  const KycIdentInitial();
}

class KycIdentLoading extends KycIdentState {
  const KycIdentLoading();
}

class KycIdentSuccess extends KycIdentState {
  const KycIdentSuccess();
}

class KycIdentFailure extends KycIdentState {
  final FailureStatus status;
  final String? errorMessage;

  const KycIdentFailure({required this.status, this.errorMessage});

  @override
  List<Object?> get props => [status, errorMessage];
}
