part of 'kyc_phone_change_cubit.dart';

abstract class KycPhoneChangeState extends Equatable {
  const KycPhoneChangeState();

  @override
  List<Object?> get props => [];
}

class KycPhoneChangeInitial extends KycPhoneChangeState {
  const KycPhoneChangeInitial();
}

class KycPhoneChangeLoading extends KycPhoneChangeState {
  const KycPhoneChangeLoading();
}

class KycPhoneChangeSuccess extends KycPhoneChangeState {
  const KycPhoneChangeSuccess();
}

class KycPhoneChangeFailure extends KycPhoneChangeState {
  final String message;

  const KycPhoneChangeFailure(this.message);

  @override
  List<Object?> get props => [message];
}
