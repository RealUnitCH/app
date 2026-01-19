import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/models/price_point.dart';
import 'package:realunit_wallet/packages/service/price_service.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/styles/currency.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc(this._service, {required this.asset, required Currency initialCurrency})
      : super(DashboardState(price: BigInt.zero, priceChart: [], currency: initialCurrency)) {
    on<RefreshPriceEvent>(_onRefreshPriceEvent);
    on<RefreshPriceChartEvent>(_onRefreshPriceChartEvent);
    on<CurrencyChangedEvent>(_onCurrencyChangedEvent);
    refresh();
  }

  void refresh() {
    add(RefreshPriceEvent());
    add(RefreshPriceChartEvent());
  }

  final APriceService _service;
  final Asset asset;

  Future<void> _onRefreshPriceEvent(RefreshPriceEvent event, Emitter<DashboardState> emit) async {
    final price = await _service.getPriceOfAsset(realUnitAsset, state.currency);
    emit(state.copyWith(price: price));
  }

  Future<void> _onRefreshPriceChartEvent(
      RefreshPriceChartEvent event, Emitter<DashboardState> emit) async {
    final priceChart = await _service.getPriceChart(realUnitAsset, state.currency);
    emit(state.copyWith(priceChart: priceChart));
  }

  void _onCurrencyChangedEvent(CurrencyChangedEvent event, Emitter<DashboardState> emit) {
    emit(state.copyWith(currency: event.currency));
    refresh();
  }
}
