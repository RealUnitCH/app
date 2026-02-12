part of 'kyc_nationality_cubit.dart';

abstract class KycNationalityState extends Equatable {
  const KycNationalityState();

  @override
  List<Object?> get props => [];
}

class KycNationalityInitial extends KycNationalityState {
  const KycNationalityInitial();
}

class KycNationalityLoading extends KycNationalityState {
  const KycNationalityLoading();
}

class KycNationalitySuccess extends KycNationalityState {
  const KycNationalitySuccess();
}

class KycNationalityFailure extends KycNationalityState {
  final String message;

  const KycNationalityFailure(this.message);

  @override
  List<Object?> get props => [message];
}
