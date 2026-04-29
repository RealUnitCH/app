import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_buy_payment_info_service.dart';

part 'buy_confirm_state.dart';

class BuyConfirmCubit extends Cubit<BuyConfirmState> {
  final RealUnitBuyPaymentInfoService _buyPaymentInfoService;

  BuyConfirmCubit(RealUnitBuyPaymentInfoService buyPaymentInfoService)
    : _buyPaymentInfoService = buyPaymentInfoService,
      super(BuyConfirmInitial());

  Future<void> confirmPayment(int paymentInfoId) async {
    try {
      emit(BuyConfirmLoading());
      final reference = await _buyPaymentInfoService.confirmPayment(paymentInfoId);
      emit(BuyConfirmSuccess(reference));
    } on ApiException catch (e) {
      developer.log(e.toString());
      emit(
        BuyConfirmFailure(
          kind: e.statusCode == 503
              ? BuyConfirmFailureKind.aktionariat
              : BuyConfirmFailureKind.generic,
          error: e.toString(),
        ),
      );
    } catch (e) {
      developer.log(e.toString());
      emit(BuyConfirmFailure(kind: BuyConfirmFailureKind.generic, error: e.toString()));
    }
  }
}
