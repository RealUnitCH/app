import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/payment/buy_exceptions.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/payment_info_error.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/sell_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_sell_payment_info_service.dart';
import 'package:realunit_wallet/styles/currency.dart';

part 'sell_payment_info_state.dart';

class SellPaymentInfoCubit extends Cubit<SellPaymentInfoState> {
  final RealUnitSellPaymentInfoService _sellPaymentInfoService;

  SellPaymentInfoCubit(this._sellPaymentInfoService) : super(const SellPaymentInfoInitial());

  Future<void> getPaymentInfo({
    String amount = '1000',
    Currency currency = Currency.chf,
    required String iban,
  }) async {
    try {
      emit(const SellPaymentInfoLoading());

      final paymentInfo = await _sellPaymentInfoService.getPaymentInfo(
        double.parse(amount).round(),
        iban,
        currency: currency,
      );

      emit(SellPaymentInfoSuccess(paymentInfo));
    } on KycLevelRequiredException catch (e) {
      emit(SellPaymentInfoFailure(
        PaymentInfoError.kycRequired,
        message: e.toString(),
      ));
    } on RegistrationRequiredException catch (e) {
      emit(SellPaymentInfoFailure(
        PaymentInfoError.registrationRequired,
        message: e.toString(),
      ));
    } catch (e) {
      developer.log(e.toString());
      emit(SellPaymentInfoFailure(
        PaymentInfoError.unknown,
        message: e.toString(),
      ));
    }
  }
}
