part of 'sell_payment_info_cubit.dart';

abstract class SellPaymentInfoState extends Equatable {
  const SellPaymentInfoState();

  @override
  List<Object?> get props => [];
}

class SellPaymentInfoInitial extends SellPaymentInfoState {
  const SellPaymentInfoInitial();
}

class SellPaymentInfoLoading extends SellPaymentInfoState {
  const SellPaymentInfoLoading();
}

class SellPaymentInfoSuccess extends SellPaymentInfoState {
  final SellPaymentInfo sellPaymentInfo;

  const SellPaymentInfoSuccess(this.sellPaymentInfo);

  @override
  List<Object?> get props => [sellPaymentInfo];
}

class SellPaymentInfoFailure extends SellPaymentInfoState {
  final PaymentInfoError error;
  final String message;
  final int? requiredLevel;

  const SellPaymentInfoFailure(this.error, {this.message = '', this.requiredLevel});

  @override
  List<Object?> get props => [error, message, requiredLevel];
}
