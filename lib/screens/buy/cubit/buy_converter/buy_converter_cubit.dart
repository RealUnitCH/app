import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_brokerbot_service.dart';
import 'package:realunit_wallet/screens/buy/cubit/buy_converter/buy_converter_state.dart';

class BuyConverterCubit extends Cubit<BuyConverterState> {
  final DfxBrokerbotService _brokerbotService;

  BuyConverterCubit(this._brokerbotService) : super(const BuyConverterState());

  Timer? _chfDebounce;
  Timer? _sharesDebounce;

  /// User changed CHF → convert to shares
  void onChfChanged(String value) {
    emit(state.copyWith(chfText: value));

    _chfDebounce?.cancel();
    _chfDebounce = Timer(const Duration(milliseconds: 500), () async {
      final amount = double.tryParse(value.replaceAll(",", "."));
      if (amount == null || amount <= 0) {
        emit(state.copyWith(sharesText: ""));
        return;
      }

      emit(state.copyWith(loading: true));

      try {
        final result = await _brokerbotService.getShares(amount);
        emit(state.copyWith(
          sharesText: result.shares.round().toString(),
          loading: false,
        ));
      } catch (e) {
        developer.log(e.toString());
        emit(state.copyWith(loading: false));
      }
    });
  }

  /// User changed shares → convert to CHF
  void onSharesChanged(String value) {
    emit(state.copyWith(sharesText: value));

    _sharesDebounce?.cancel();
    _sharesDebounce = Timer(const Duration(milliseconds: 500), () async {
      final shares = double.tryParse(value.replaceAll(",", "."));
      if (shares == null || shares <= 0) {
        emit(state.copyWith(chfText: ""));
        return;
      }

      emit(state.copyWith(loading: true));

      try {
        final result = await _brokerbotService.getBuyPrice(shares);
        emit(state.copyWith(
          chfText: result.totalCost.toStringAsFixed(_fractionDigits(value)),
          loading: false,
        ));
      } catch (e) {
        developer.log(e.toString());
        emit(state.copyWith(loading: false));
      }
    });
  }

  int _fractionDigits(String input) {
    if (!input.contains(".")) return 2;
    return input.split(".").last.length;
  }

  @override
  Future<void> close() {
    _chfDebounce?.cancel();
    _sharesDebounce?.cancel();
    return super.close();
  }
}
