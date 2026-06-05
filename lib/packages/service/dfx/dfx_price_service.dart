import 'dart:convert';

import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/models/price_point.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/price/dto/real_unit_price_dto.dart';
import 'package:realunit_wallet/packages/service/price_service.dart';
import 'package:realunit_wallet/styles/currency.dart';

class DFXPriceService extends APriceService {
  static const _priceHistoryPath = '/v1/realunit/price/history';
  static const _pricePath = '/v1/realunit/price';

  final AppStore _appStore;

  DFXPriceService(this._appStore);

  String get _host => _appStore.apiConfig.apiHost;

  double? _priceFor(RealUnitPriceDto dto, Currency currency) => switch (currency) {
    Currency.eur => dto.eur,
    Currency.chf => dto.chf,
  };

  @override
  Future<List<PricePoint>> getPriceChart(Asset asset, Currency currency) async {
    final uri = buildUri(_host, _priceHistoryPath, {'timeFrame': 'ALL'});
    final response = await _appStore.httpClient.get(uri);

    if (response.statusCode != 200) throw Exception(response.body);

    final body = jsonDecode(response.body) as List;

    final result = <PricePoint>[];

    for (final entry in body) {
      final dto = RealUnitPriceDto.fromJson(entry as Map<String, dynamic>);
      final price = _priceFor(dto, currency);

      // Skip points the backend has not priced yet (e.g. the current day before
      // the daily fixing). A null value would otherwise crash the multiplication,
      // and a point without a timestamp cannot be placed on the time axis.
      if (price == null || dto.timestamp == null) continue;

      result.add(
        PricePoint(
          asset: asset,
          price: BigInt.from(price * 100),
          time: dto.timestamp!,
        ),
      );
    }

    return result;
  }

  @override
  Future<BigInt> getPriceOfAsset(Asset asset, Currency currency) async {
    final uri = buildUri(_host, _pricePath);
    final response = await _appStore.httpClient.get(uri);

    if (response.statusCode != 200) throw Exception(response.body);

    final dto = RealUnitPriceDto.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    final price = _priceFor(dto, currency);

    // The backend returns only a timestamp when no price is published yet; surface
    // it as the zero sentinel the dashboard already renders as "--.--".
    if (price == null) return BigInt.zero;

    return BigInt.from(price * 100);
  }

  /// Returns the equivalent EUR amount for 1 CHF
  Future<double> getChfToEurRate() async {
    final uri = buildUri(_host, _pricePath);
    final response = await _appStore.httpClient.get(uri);

    if (response.statusCode != 200) throw Exception(response.body);

    final dto = RealUnitPriceDto.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    final chf = dto.chf ?? 0;
    final eur = dto.eur ?? 0;

    return chf > 0 ? eur / chf : 0.0;
  }
}
