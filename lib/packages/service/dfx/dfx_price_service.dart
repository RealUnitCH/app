import 'dart:convert';

import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/models/price_point.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/price_service.dart';
import 'package:realunit_wallet/styles/currency.dart';

class DFXPriceService extends APriceService {
  static const _priceHistoryPath = '/v1/realunit/price/history';
  static const _pricePath = '/v1/realunit/price';

  final AppStore _appStore;

  DFXPriceService(this._appStore);

  String get _host => _appStore.apiConfig.apiHost;

  @override
  Future<List<PricePoint>> getPriceChart(Asset asset, Currency currency) async {
    final uri = buildUri(_host, _priceHistoryPath, {'timeFrame': 'ALL'});
    final response = await _appStore.httpClient.get(uri);

    if (response.statusCode != 200) throw Exception(response.body);

    final body = jsonDecode(response.body) as List<dynamic>;

    final result = <PricePoint>[];

    for (final raw in body) {
      final entry = raw as Map<String, dynamic>;
      final rawPrice = switch (currency) {
        Currency.eur => entry['eur'] as num?,
        Currency.chf => entry['chf'] as num?,
      };
      // The API omits the price for points it cannot quote (e.g. the latest
      // point while the quote is unavailable). Skip them instead of throwing,
      // which would otherwise discard the entire chart.
      if (rawPrice == null) continue;
      result.add(
        PricePoint(
          asset: asset,
          price: BigInt.from(rawPrice * 100),
          time: DateTime.parse(entry['timestamp'] as String),
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

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    final rawPrice = switch (currency) {
      Currency.eur => body['eur'] as num?,
      Currency.chf => body['chf'] as num?,
    };
    // A missing price means the quote is currently unavailable. Return zero so
    // the UI renders "--.--" instead of throwing.
    if (rawPrice == null) return BigInt.zero;
    return BigInt.from(rawPrice * 100);
  }

  /// Returns the equivalent EUR amount for 1 CHF
  Future<double> getChfToEurRate() async {
    final uri = buildUri(_host, _pricePath);
    final response = await _appStore.httpClient.get(uri);

    if (response.statusCode != 200) throw Exception(response.body);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final chf = (body['chf'] as num?)?.toDouble() ?? 0;
    final eur = (body['eur'] as num?)?.toDouble() ?? 0;

    return chf > 0 ? eur / chf : 0.0;
  }
}
