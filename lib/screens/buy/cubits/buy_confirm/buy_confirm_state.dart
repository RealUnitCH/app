part of 'buy_confirm_cubit.dart';

enum BuyConfirmError { aktionariat, unknown }

abstract class BuyConfirmState extends Equatable {
  const BuyConfirmState();

  @override
  List<Object?> get props => [];
}

class BuyConfirmInitial extends BuyConfirmState {
  const BuyConfirmInitial();
}

class BuyConfirmLoading extends BuyConfirmState {
  const BuyConfirmLoading();
}

class BuyConfirmSuccess extends BuyConfirmState {
  final String reference;

  const BuyConfirmSuccess(this.reference);

  @override
  List<Object?> get props => [reference];
}

class BuyConfirmFailure extends BuyConfirmState {
  final BuyConfirmError error;

  const BuyConfirmFailure(this.error);

  @override
  List<Object?> get props => [error];
}
