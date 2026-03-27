import 'dart:developer' as developer;

import 'package:async/async.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_price_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/payment/buy_exceptions.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy/buy_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/payment_info_error.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_buy_payment_info_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_wallet_service.dart';
import 'package:realunit_wallet/styles/currency.dart';

part 'buy_payment_info_state.dart';

const double _minAmountChf = 100;

class BuyPaymentInfoCubit extends Cubit<BuyPaymentInfoState> {
  final RealUnitBuyPaymentInfoService _buyPaymentInfoService;
  final DFXPriceService _priceService;
  final RealUnitWalletService _walletService;
  final RealUnitRegistrationService _registrationService;
  CancelableOperation<BuyPaymentInfoState>? _completer;

  BuyPaymentInfoCubit(
    RealUnitBuyPaymentInfoService buyPaymentInfoService,
    DFXPriceService priceService,
    RealUnitWalletService walletService,
    RealUnitRegistrationService registrationService,
  ) : _buyPaymentInfoService = buyPaymentInfoService,
      _priceService = priceService,
      _walletService = walletService,
      _registrationService = registrationService,
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
      final parsedAmount = _parseAmount(amount);

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

      return await _fetchPaymentInfo(parsedAmount, currency);
    } on KycLevelRequiredException catch (e) {
      return BuyPaymentInfoFailure(
        PaymentInfoError.kycRequired,
        requiredLevel: e.requiredLevel,
      );
    } on RegistrationRequiredException {
      return await _tryAutoRegisterWallet(amount, currency);
    } catch (e) {
      developer.log(e.toString());
      return const BuyPaymentInfoFailure(PaymentInfoError.unknown);
    }
  }

  Future<BuyPaymentInfoState> _tryAutoRegisterWallet(String amount, Currency currency) async {
    try {
      final walletStatus = await _walletService.getWalletStatus();
      final userData = walletStatus.realUnitUserDataDto;

      if (userData == null) {
        return const BuyPaymentInfoFailure(PaymentInfoError.registrationRequired);
      }

      await _registrationService.registerWallet(userData);

      return await _fetchPaymentInfo(_parseAmount(amount), currency);
    } catch (e) {
      developer.log('Auto wallet registration failed: $e');
      return const BuyPaymentInfoFailure(PaymentInfoError.registrationRequired);
    }
  }

  double _parseAmount(String amount) {
    final sanitized = amount.isEmpty ? '0' : amount.replaceAll(',', '.');
    return double.parse(sanitized);
  }

  Future<BuyPaymentInfoSuccess> _fetchPaymentInfo(double amount, Currency currency) async {
    final paymentInfo = await _buyPaymentInfoService.getPaymentInfo(
      amount.round(),
      currency: currency,
    );
    return BuyPaymentInfoSuccess(paymentInfo);
  }

  @override
  Future<void> close() async {
    await _completer?.cancel();
    return super.close();
  }
}
