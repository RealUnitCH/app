import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/payment/buy_exceptions.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy_payment_info_error.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_buy_payment_info_service.dart';
import 'package:realunit_wallet/styles/currency.dart';
import 'package:synchronized/synchronized.dart';

part 'buy_payment_info_state.dart';

class BuyPaymentInfoCubit extends Cubit<BuyPaymentInfoState> {
  final RealUnitBuyPaymentInfoService _buyPaymentInfoService;
  final Lock _lock = Lock();

  BuyPaymentInfoCubit(this._buyPaymentInfoService) : super(BuyPaymentInfoInitial());

  Future<void> getPaymentInfo({int amount = 300, Currency currency = Currency.chf}) async {
    await _lock.synchronized(() async {
      try {
        if (state is! BuyPaymentInfoSuccess) {
          emit(BuyPaymentInfoLoading());
        }
        final paymentInfo = await _buyPaymentInfoService.getPaymentInfo(amount, currency: currency);
        emit(BuyPaymentInfoSuccess(paymentInfo));
      } on KycLevelRequiredException {
        emit(BuyPaymentInfoFailure(BuyPaymentInfoError.kycRequired));
      } on RegistrationRequiredException {
        emit(BuyPaymentInfoFailure(BuyPaymentInfoError.registrationRequired));
      } catch (e) {
        developer.log(e.toString());
        emit(BuyPaymentInfoFailure(BuyPaymentInfoError.unknown));
      }
    });
  }
}
