part of 'buy_payment_info_cubit.dart';

abstract class BuyPaymentInfoState extends Equatable {
  const BuyPaymentInfoState();

  @override
  List<Object?> get props => [];
}

class BuyPaymentInfoInitial extends BuyPaymentInfoState {
  const BuyPaymentInfoInitial();
}

class BuyPaymentInfoLoading extends BuyPaymentInfoState {
  const BuyPaymentInfoLoading();
}

class BuyPaymentInfoSuccess extends BuyPaymentInfoState {
  final BuyPaymentInfo buyPaymentInfo;

  const BuyPaymentInfoSuccess(this.buyPaymentInfo);

  @override
  List<Object?> get props => [buyPaymentInfo];
}

class BuyPaymentInfoFailure extends BuyPaymentInfoState {
  final PaymentInfoError error;
  final int? requiredLevel;

  const BuyPaymentInfoFailure(this.error, {this.requiredLevel});

  @override
  List<Object?> get props => [error, requiredLevel];
}
