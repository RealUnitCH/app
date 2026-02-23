part of 'buy_confirm_cubit.dart';

abstract class BuyConfirmState extends Equatable {
  @override
  List<Object?> get props => [];
}

class BuyConfirmInitial extends BuyConfirmState {}

class BuyConfirmLoading extends BuyConfirmState {}

class BuyConfirmSuccess extends BuyConfirmState {
  final String reference;

  BuyConfirmSuccess(this.reference);

  @override
  List<Object?> get props => [reference];
}

class BuyConfirmFailure extends BuyConfirmState {
  final String error;

  BuyConfirmFailure(this.error);

  @override
  List<Object?> get props => [error];
}
