import 'dart:developer' as developer;

import 'package:async/async.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_price_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/payment/buy_exceptions.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy/buy_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/payment_info_error.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_buy_payment_info_service.dart';
import 'package:realunit_wallet/styles/currency.dart';

part 'buy_payment_info_state.dart';

const double _minAmountChf = 100;

class BuyPaymentInfoCubit extends Cubit<BuyPaymentInfoState> {
  final RealUnitBuyPaymentInfoService _buyPaymentInfoService;
  final DFXPriceService _priceService;
  CancelableOperation<BuyPaymentInfoState>? _completer;

  BuyPaymentInfoCubit(
    RealUnitBuyPaymentInfoService buyPaymentInfoService,
    DFXPriceService priceService,
  ) : _buyPaymentInfoService = buyPaymentInfoService,
      _priceService = priceService,
      super(const BuyPaymentInfoInitial());

  Future<void> getPaymentInfo({String amount = '300', Currency currency = Currency.chf}) async {
    await _completer?.cancel();

    if (state is! BuyPaymentInfoSuccess) {
      emit(const BuyPaymentInfoLoading());
    }

    _completer = CancelableOperation.fromFuture(
      _runGetPaymentInfo(amount, currency),
    );

    final newState = await _completer!.value;
    emit(newState);
  }

  Future<BuyPaymentInfoState> _runGetPaymentInfo(String amount, Currency currency) async {
    try {
      final sanitizedAmount = amount.isEmpty ? '0' : amount.replaceAll(',', '.');
      final parsedAmount = double.parse(sanitizedAmount);

      double minAmount = _minAmountChf;
      if (currency == Currency.eur) {
        final chfToEurRate = await _priceService.getChfToEurRate();
        minAmount = (_minAmountChf * chfToEurRate).ceilToDouble();
      }

      if (parsedAmount < minAmount) {
        return BuyPaymentInfoMinAmountNotMetFailure(
          PaymentInfoError.minAmountNotMet,
          minAmount: minAmount,
        );
      }
      final paymentInfo = await _buyPaymentInfoService.getPaymentInfo(
        parsedAmount.round(),
        currency: currency,
      );
      return BuyPaymentInfoSuccess(paymentInfo);
    } on KycLevelRequiredException catch (e) {
      return BuyPaymentInfoFailure(
        PaymentInfoError.kycRequired,
        requiredLevel: e.requiredLevel,
      );
    } on RegistrationRequiredException {
      return const BuyPaymentInfoFailure(PaymentInfoError.registrationRequired);
    } on BitboxNotConnectedException {
      return const BuyPaymentInfoFailure(PaymentInfoError.bitboxDisconnected);
    } catch (e) {
      developer.log(e.toString());
      return const BuyPaymentInfoFailure(PaymentInfoError.unknown);
    }
  }

  @override
  Future<void> close() async {
    await _completer?.cancel();
    return super.close();
  }
}
