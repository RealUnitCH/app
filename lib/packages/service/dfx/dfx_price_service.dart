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

    final body = jsonDecode(response.body) as List;

    final result = <PricePoint>[];

    for (final entry in body) {
      final rawPrice = switch (currency) {
        Currency.eur => entry['eur'],
        Currency.chf => entry['chf'],
      };
      // The API omits the price for points it cannot quote (e.g. the latest
      // point while the quote is unavailable). Skip them instead of throwing,
      // which would otherwise discard the entire chart.
      if (rawPrice == null) continue;
      result.add(
        PricePoint(
          asset: asset,
          // Round the fractional-unit price (e.g. 4.56 CHF → 456 rappen);
          // `BigInt.from` on the raw `double * 100` truncates toward zero and
          // would drop a rappen on values like 4.56 (455.999… → 455). Values
          // such as 1.23 are exactly 123.0 in IEEE-754 and were never truncated.
          price: BigInt.from(((rawPrice as num) * 100).round()),
          time: DateTime.parse(entry['timestamp']),
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

    final body = jsonDecode(response.body);

    final rawPrice = switch (currency) {
      Currency.eur => body['eur'],
      Currency.chf => body['chf'],
    };
    // A missing price means the quote is currently unavailable. Return zero so
    // the UI renders "--.--" instead of throwing.
    if (rawPrice == null) return BigInt.zero;
    return BigInt.from(((rawPrice as num) * 100).round());
  }

  /// Returns the equivalent EUR amount for 1 CHF
  Future<double> getChfToEurRate() async {
    final uri = buildUri(_host, _pricePath);
    final response = await _appStore.httpClient.get(uri);

    if (response.statusCode != 200) throw Exception(response.body);

    final body = jsonDecode(response.body);
    final chf = (body['chf'] as num?)?.toDouble() ?? 0;
    final eur = (body['eur'] as num?)?.toDouble() ?? 0;

    return chf > 0 ? eur / chf : 0.0;
  }
}
