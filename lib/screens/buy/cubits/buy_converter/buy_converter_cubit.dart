import 'dart:async';
import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_brokerbot_service.dart';
import 'package:realunit_wallet/styles/currency.dart';

part 'buy_converter_state.dart';

class BuyConverterCubit extends Cubit<BuyConverterState> {
  final DfxBrokerbotService _brokerbotService;

  BuyConverterCubit(this._brokerbotService) : super(const BuyConverterState());

  Timer? _fiatDebounce;
  Timer? _sharesDebounce;

  /// User changed fiat → convert to shares
  Future<void> onFiatChanged(String value) async {
    emit(state.copyWith(fiatText: value));

    _fiatDebounce?.cancel();
    _fiatDebounce = Timer(const Duration(milliseconds: 100), () async {
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

  /// User changed shares → convert to fiat
  Future<void> onSharesChanged(String value) async {
    emit(state.copyWith(sharesText: value));

    _sharesDebounce?.cancel();
    _sharesDebounce = Timer(const Duration(milliseconds: 100), () async {
      final shares = int.tryParse(value);
      if (shares == null || shares <= 0) {
        emit(state.copyWith(fiatText: ""));
        return;
      }

      emit(state.copyWith(loading: true));

      try {
        final result = await _brokerbotService.getBuyPrice(shares);
        emit(state.copyWith(
          fiatText: result.totalCost.toStringAsFixed(_fractionDigits(value)),
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
    _fiatDebounce?.cancel();
    _sharesDebounce?.cancel();
    return super.close();
  }
}
