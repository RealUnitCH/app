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
  DashboardBloc(this._service, {required this.asset, required this.currency})
      : super(DashboardState(price: BigInt.zero, priceChart: [])) {
    on<RefreshPriceEvent>(_onRefreshPriceEvent);
    on<RefreshPriceChartEvent>(_onRefreshPriceChartEvent);

    add(RefreshPriceEvent());
    add(RefreshPriceChartEvent());
  }

  final APriceService _service;
  final Asset asset;
  final Currency currency;

  Future<void> _onRefreshPriceEvent(
      RefreshPriceEvent event, Emitter<DashboardState> emit) async {
    final price = await _service.getPriceOfAsset(realUnitAsset, currency);
    emit(state.copyWith(price: price));
  }

  Future<void> _onRefreshPriceChartEvent(
      RefreshPriceChartEvent event, Emitter<DashboardState> emit) async {
    final priceChart = await _service.getPriceChart(realUnitAsset, currency);
    emit(state.copyWith(priceChart: priceChart));
  }
}
