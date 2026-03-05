import 'dart:developer' as developer;

import 'package:async/async.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/payment/buy_exceptions.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy/buy_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/payment_info_error.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_buy_payment_info_service.dart';
import 'package:realunit_wallet/styles/currency.dart';

part 'buy_payment_info_state.dart';

class BuyPaymentInfoCubit extends Cubit<BuyPaymentInfoState> {
  final RealUnitBuyPaymentInfoService _buyPaymentInfoService;
  CancelableOperation<BuyPaymentInfoState>? _completer;

  BuyPaymentInfoCubit(this._buyPaymentInfoService) : super(const BuyPaymentInfoInitial());

  Future<void> getPaymentInfo({String amount = '100', Currency currency = Currency.chf}) async {
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
      if (parsedAmount < 100) {
        return const BuyPaymentInfoFailure(PaymentInfoError.minAmountNotMet);
      }
      final paymentInfo = await _buyPaymentInfoService.getPaymentInfo(
        parsedAmount.round(),
        currency: currency,
      );
      return BuyPaymentInfoSuccess(paymentInfo);
    } on KycLevelRequiredException {
      return const BuyPaymentInfoFailure(PaymentInfoError.kycRequired);
    } on RegistrationRequiredException {
      return const BuyPaymentInfoFailure(PaymentInfoError.registrationRequired);
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
