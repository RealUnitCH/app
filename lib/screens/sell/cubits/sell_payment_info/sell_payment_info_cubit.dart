import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/models/sell/sell_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_sell_payment_info_service.dart';
import 'package:realunit_wallet/styles/currency.dart';

part 'sell_payment_info_state.dart';

class SellPaymentInfoCubit extends Cubit<SellPaymentInfoState> {
  final RealUnitSellPaymentInfoService _sellPaymentInfoService;

  SellPaymentInfoCubit(this._sellPaymentInfoService) : super(SellPaymentInfoInitial());

  Future<void> getPaymentInfo({
    String amount = '1000',
    Currency currency = Currency.chf,
    required String iban,
  }) async {
    try {
      emit(SellPaymentInfoLoading());

      final paymentInfo = await _sellPaymentInfoService.getPaymentInfo(
        double.parse(amount).round(),
        iban,
        currency: currency,
      );

      emit(SellPaymentInfoSuccess(paymentInfo));
    } catch (e) {
      developer.log(e.toString());
      emit(SellPaymentInfoFailure(e.toString()));
    }
  }
}
