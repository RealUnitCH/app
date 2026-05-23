import 'dart:async';
import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_brokerbot_service.dart';
import 'package:realunit_wallet/styles/currency.dart';

part 'sell_converter_state.dart';

class SellConverterCubit extends Cubit<SellConverterState> {
  final DfxBrokerbotService _brokerbotService;

  SellConverterCubit(this._brokerbotService) : super(const SellConverterState());

  Timer? _fiatDebounce;
  Timer? _sharesDebounce;

  /// User changed fiat → convert to shares
  Future<void> onFiatChanged(String value, {Currency currency = Currency.chf}) async {
    emit(state.copyWith(fiatText: value));

    _fiatDebounce?.cancel();
    _fiatDebounce = Timer(const Duration(milliseconds: 100), () async {
      if (isClosed) return;
      emit(state.copyWith(loading: true));

      try {
        final result = await _brokerbotService.getSellShares(value, currency);
        if (isClosed) return;
        emit(
          state.copyWith(
            sharesText: result.shares.toString(),
            loading: false,
          ),
        );
      } catch (e) {
        developer.log(e.toString());
        if (isClosed) return;
        emit(state.copyWith(loading: false));
      }
    });
  }

  /// User changed shares → convert to fiat
  Future<void> onSharesChanged(String value, {Currency currency = Currency.chf}) async {
    emit(state.copyWith(sharesText: value));

    _sharesDebounce?.cancel();
    _sharesDebounce = Timer(const Duration(milliseconds: 100), () async {
      if (isClosed) return;
      emit(state.copyWith(loading: true));

      try {
        final result = await _brokerbotService.getSellPrice(value, currency);
        if (isClosed) return;
        emit(
          state.copyWith(
            fiatText: result.estimatedAmount.toStringAsFixed(_fractionDigits(value)),
            loading: false,
          ),
        );
      } catch (e) {
        developer.log(e.toString());
        if (isClosed) return;
        emit(state.copyWith(loading: false));
      }
    });
  }

  Future<void> onCurrencyChanged(Currency currency) async {
    emit(state.copyWith(loading: true));
    try {
      final result = await _brokerbotService.getBuyPrice(state.sharesText, currency);
      if (isClosed) return;
      emit(
        state.copyWith(
          fiatText: result.totalCost.toStringAsFixed(_fractionDigits(state.sharesText)),
          loading: false,
          currency: currency,
        ),
      );
    } catch (e) {
      developer.log(e.toString());
      if (isClosed) return;
      emit(
        state.copyWith(
          loading: false,
          currency: currency,
        ),
      );
    }
  }

  int _fractionDigits(String input) {
    if (!input.contains('.')) return 2;
    return input.split('.').last.length;
  }

  @override
  Future<void> close() {
    _fiatDebounce?.cancel();
    _sharesDebounce?.cancel();
    return super.close();
  }
}
