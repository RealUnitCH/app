import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_buy_payment_info_service.dart';
import 'package:realunit_wallet/styles/currency.dart';

part 'buy_payment_info_state.dart';

class BuyPaymentInfoCubit extends Cubit<BuyPaymentInfoState> {
  final RealUnitBuyPaymentInfoService _buyPaymentInfoService;

  BuyPaymentInfoCubit(this._buyPaymentInfoService) : super(BuyPaymentInfoState());

  Future<void> getPaymentInfo({int amount = 300, Currency currency = Currency.chf}) async {
    try {
      if (state.buyPaymentInfo == null) {
        emit(state.copyWith(status: BuyPaymentInfoStatus.loading));
      }
      final paymentInfo = await _buyPaymentInfoService.getPaymentInfo(amount, currency: currency);
      emit(state.copyWith(status: BuyPaymentInfoStatus.success, buyPaymentInfo: paymentInfo));
    } catch (e) {
      emit(state.copyWith(status: BuyPaymentInfoStatus.failure));
    }
  }
}
