part of 'buy_payment_info_cubit.dart';

class BuyPaymentInfoState extends Equatable {
  final BuyPaymentInfoStatus status;
  final DfxBuyPaymentInfo? buyPaymentInfo;

  const BuyPaymentInfoState({this.status = BuyPaymentInfoStatus.initial, this.buyPaymentInfo});

  BuyPaymentInfoState copyWith({
    BuyPaymentInfoStatus? status,
    DfxBuyPaymentInfo? buyPaymentInfo,
  }) {
    return BuyPaymentInfoState(
      status: status ?? this.status,
      buyPaymentInfo: buyPaymentInfo ?? this.buyPaymentInfo,
    );
  }

  @override
  List<Object?> get props => [status, buyPaymentInfo];
}

enum BuyPaymentInfoStatus { initial, loading, success, failure }
