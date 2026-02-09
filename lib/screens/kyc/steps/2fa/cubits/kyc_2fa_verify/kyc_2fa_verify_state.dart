part of 'kyc_2fa_verify_cubit.dart';

abstract class Kyc2FaVerifyState extends Equatable {
  const Kyc2FaVerifyState();

  @override
  List<Object?> get props => [];
}

class Kyc2FaVerifyInitial extends Kyc2FaVerifyState {
  const Kyc2FaVerifyInitial();
}

class Kyc2FaVerifyLoading extends Kyc2FaVerifyState {
  const Kyc2FaVerifyLoading();
}

class Kyc2FaVerifySuccess extends Kyc2FaVerifyState {
  const Kyc2FaVerifySuccess();
}

class Kyc2FaVerifyFailure extends Kyc2FaVerifyState {
  final String errorMessage;

  const Kyc2FaVerifyFailure({required this.errorMessage});

  @override
  List<Object> get props => [errorMessage];
}
