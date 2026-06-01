import 'dart:developer' as developer;

import 'package:async/async.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/payment/buy_exceptions.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy/buy_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/payment_info_error.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_buy_payment_info_service.dart';
import 'package:realunit_wallet/styles/currency.dart';

part 'buy_payment_info_state.dart';

// Backend QuoteError code for the "amount below the per-currency minimum"
// case. The API returns this in the success body's `error` field together
// with the authoritative `minVolume`; the app surfaces it as a typed state
// for the UI to render. Other QuoteError values (KYC, limit, …) are
// already routed via dedicated ApiExceptions and dedicated failure states.
const String _quoteErrorAmountTooLow = 'AmountTooLow';

class BuyPaymentInfoCubit extends Cubit<BuyPaymentInfoState> {
  final RealUnitBuyPaymentInfoService _buyPaymentInfoService;
  CancelableOperation<BuyPaymentInfoState>? _completer;

  BuyPaymentInfoCubit(
    RealUnitBuyPaymentInfoService buyPaymentInfoService,
  ) : _buyPaymentInfoService = buyPaymentInfoService,
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
    if (isClosed) return;
    emit(newState);
  }

  Future<BuyPaymentInfoState> _runGetPaymentInfo(String amount, Currency currency) async {
    try {
      final sanitizedAmount = amount.isEmpty ? '0' : amount.replaceAll(',', '.');
      final parsedAmount = double.parse(sanitizedAmount);

      final paymentInfo = await _buyPaymentInfoService.getPaymentInfo(
        parsedAmount.round(),
        currency: currency,
      );

      // Only the backend knows the current per-currency limits, exchange
      // rates and any compliance gating — when it tags the quote
      // `isValid: false` we surface its verdict without re-interpreting it.
      if (!paymentInfo.isValid) {
        if (paymentInfo.error == _quoteErrorAmountTooLow && paymentInfo.minVolume != null) {
          return BuyPaymentInfoMinAmountNotMetFailure(
            PaymentInfoError.minAmountNotMet,
            minAmount: paymentInfo.minVolume!,
          );
        }
        return BuyPaymentInfoFailure(
          PaymentInfoError.unknown,
          message: paymentInfo.error ?? '',
        );
      }
      return BuyPaymentInfoSuccess(paymentInfo);
    } on KycLevelRequiredException catch (e) {
      return BuyPaymentInfoFailure(
        PaymentInfoError.kycRequired,
        message: e.toString(),
        requiredLevel: e.requiredLevel,
        context: e.context,
      );
    } on RegistrationRequiredException catch (e) {
      return BuyPaymentInfoFailure(
        PaymentInfoError.registrationRequired,
        context: e.context,
        message: e.toString(),
      );
    } on BitboxNotConnectedException catch (e) {
      return BuyPaymentInfoFailure(
        PaymentInfoError.bitboxDisconnected,
        message: e.toString(),
      );
    } on ApiException catch (e) {
      // 503 / PRICE_SOURCE_UNAVAILABLE means the external price provider
      // (Aktionariat) is down, so no quote can be built — surface that
      // explicitly instead of a generic failure. Must stay below the
      // KYC/Registration clauses (those are ApiException subclasses).
      if (e.statusCode == 503 || e.code == 'PRICE_SOURCE_UNAVAILABLE') {
        return const BuyPaymentInfoFailure(PaymentInfoError.priceSourceUnavailable);
      }
      developer.log(e.toString());
      return BuyPaymentInfoFailure(PaymentInfoError.unknown, message: e.toString());
    } catch (e) {
      developer.log(e.toString());
      return BuyPaymentInfoFailure(
        PaymentInfoError.unknown,
        message: e.toString(),
      );
    }
  }

  @override
  Future<void> close() async {
    await _completer?.cancel();
    return super.close();
  }
}
