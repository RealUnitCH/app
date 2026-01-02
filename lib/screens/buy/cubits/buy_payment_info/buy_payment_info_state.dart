part of 'buy_payment_info_cubit.dart';

abstract class BuyPaymentInfoState extends Equatable {
  const BuyPaymentInfoState();

  @override
  List<Object?> get props => [];
}

class BuyPaymentInfoInitial extends BuyPaymentInfoState {}

class BuyPaymentInfoLoading extends BuyPaymentInfoState {}

class BuyPaymentInfoSuccess extends BuyPaymentInfoState {
  final BuyPaymentInfo buyPaymentInfo;

  const BuyPaymentInfoSuccess(this.buyPaymentInfo);

  @override
  List<Object?> get props => [buyPaymentInfo];
}

class BuyPaymentInfoFailure extends BuyPaymentInfoState {
  final BuyPaymentInfoError error;

  const BuyPaymentInfoFailure(this.error);

  @override
  List<Object?> get props => [error];
}
