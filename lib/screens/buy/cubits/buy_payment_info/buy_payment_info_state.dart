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

  /// KYC routing context forwarded as `extra` when the failure routes the user
  /// into the KYC flow (see `payment_additional_action_needed_button.dart`).
  final String? context;

  /// Human-readable backend error text (e.g. the raw API message), surfaced in
  /// the failure UI. Empty when the failure carries no message.
  final String message;

  const BuyPaymentInfoFailure(
    this.error, {
    this.requiredLevel,
    this.context,
    this.message = '',
  });

  @override
  List<Object?> get props => [error, requiredLevel, context, message];
}

class BuyPaymentInfoMinAmountNotMetFailure extends BuyPaymentInfoFailure {
  final double minAmount;

  const BuyPaymentInfoMinAmountNotMetFailure(super.error, {required this.minAmount});

  @override
  List<Object?> get props => [error, minAmount];
}
