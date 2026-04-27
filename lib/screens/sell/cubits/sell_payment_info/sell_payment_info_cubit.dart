import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_price_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/payment/buy_exceptions.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/tfa_required_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/payment_info_error.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/sell_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_sell_payment_info_service.dart';
import 'package:realunit_wallet/styles/currency.dart';

part 'sell_payment_info_state.dart';

const double _minAmountChf = 10;

class SellPaymentInfoCubit extends Cubit<SellPaymentInfoState> {
  final RealUnitSellPaymentInfoService _sellPaymentInfoService;
  final DFXPriceService _priceService;

  SellPaymentInfoCubit(
    RealUnitSellPaymentInfoService sellPaymentInfoService,
    DFXPriceService priceService,
  ) : _sellPaymentInfoService = sellPaymentInfoService,
      _priceService = priceService,
      super(const SellPaymentInfoInitial());

  Future<void> getPaymentInfo({
    String amount = '100',
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
      emit(
        SellPaymentInfoFailure(
          PaymentInfoError.kycRequired,
          message: e.toString(),
          requiredLevel: e.requiredLevel,
        ),
      );
    } on RegistrationRequiredException catch (e) {
      emit(
        SellPaymentInfoFailure(
          PaymentInfoError.registrationRequired,
          message: e.toString(),
        ),
      );
    } on TfaRequiredException catch (e) {
      emit(
        SellPaymentInfoFailure(
          PaymentInfoError.tfaRequired,
          message: e.toString(),
        ),
      );
    } catch (e) {
      developer.log(e.toString());
      emit(
        SellPaymentInfoFailure(
          PaymentInfoError.unknown,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> validateMinAmount({
    required String fiatAmount,
    Currency currency = Currency.chf,
  }) async {
    try {
      final sanitizedAmount = fiatAmount.isEmpty ? '0' : fiatAmount.replaceAll(',', '.');
      final parsedAmount = double.tryParse(sanitizedAmount) ?? 0;

      double minAmount = _minAmountChf;
      if (currency == Currency.eur) {
        final chfToEurRate = await _priceService.getChfToEurRate();
        minAmount = (_minAmountChf * chfToEurRate).ceilToDouble();
      }

      if (parsedAmount < minAmount) {
        emit(
          SellPaymentInfoMinAmountNotMet(
            minAmount: minAmount,
            currency: currency,
          ),
        );
      } else if (state is SellPaymentInfoMinAmountNotMet) {
        emit(const SellPaymentInfoInitial());
      }
    } catch (e) {
      developer.log(
        'Error validating min amount: $e',
        name: '$SellPaymentInfoCubit',
      );
    }
  }
}
