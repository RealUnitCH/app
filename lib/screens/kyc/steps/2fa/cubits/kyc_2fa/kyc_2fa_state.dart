part of 'kyc_2fa_cubit.dart';

abstract class Kyc2FaState extends Equatable {
  const Kyc2FaState();

  @override
  List<Object?> get props => [];
}

class Kyc2FaInitial extends Kyc2FaState {}

class Kyc2FaLoading extends Kyc2FaState {}

class Kyc2FaSuccess extends Kyc2FaState {}

class Kyc2FaFailure extends Kyc2FaState {}
