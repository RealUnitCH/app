part of 'sell_confirm_cubit.dart';

abstract class SellConfirmState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SellConfirmInitial extends SellConfirmState {}

class SellConfirmLoading extends SellConfirmState {}

class SellConfirmSuccess extends SellConfirmState {}

class SellConfirmFailure extends SellConfirmState {
  final String error;

  SellConfirmFailure(this.error);

  @override
  List<Object?> get props => [error];
}
