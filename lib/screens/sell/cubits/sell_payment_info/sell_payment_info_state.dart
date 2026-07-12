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
  final bool isBitbox;

  const SellPaymentInfoSuccess(this.sellPaymentInfo, {required this.isBitbox});

  @override
  List<Object?> get props => [sellPaymentInfo, isBitbox];
}

class SellPaymentInfoFailure extends SellPaymentInfoState {
  final PaymentInfoError error;
  final String message;
  final int? requiredLevel;
  final String? context;

  const SellPaymentInfoFailure(this.error, {this.message = '', this.requiredLevel, this.context});

  @override
  List<Object?> get props => [error, message, requiredLevel, context];
}

class SellPaymentInfoMinAmountNotMet extends SellPaymentInfoState {
  final double minAmount;
  final Currency currency;

  const SellPaymentInfoMinAmountNotMet({required this.minAmount, required this.currency});

  @override
  List<Object?> get props => [minAmount, currency];
}
