part of 'kyc_address_change_cubit.dart';

abstract class KycAddressChangeState extends Equatable {
  const KycAddressChangeState();

  @override
  List<Object?> get props => [];
}

class KycAddressChangeInitial extends KycAddressChangeState {
  const KycAddressChangeInitial();
}

class KycAddressChangeLoading extends KycAddressChangeState {
  const KycAddressChangeLoading();
}

class KycAddressChangeSuccess extends KycAddressChangeState {
  const KycAddressChangeSuccess();
}

class KycAddressChangeFailure extends KycAddressChangeState {
  final String message;

  const KycAddressChangeFailure(this.message);

  @override
  List<Object?> get props => [message];
}
