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
      BigInt price;
      switch (currency) {
        case Currency.eur:
          price = BigInt.from(entry['eur'] * 100);
          break;
        case Currency.chf:
          price = BigInt.from(entry['chf'] * 100);
          break;
      }
      result.add(PricePoint(
        asset: asset,
        price: price,
        time: DateTime.parse(entry['timestamp']),
      ));
    }

    return result;
  }

  @override
  Future<BigInt> getPriceOfAsset(Asset asset, Currency currency) async {
    final uri = buildUri(_host, _pricePath);
    final response = await _appStore.httpClient.get(uri);

    if (response.statusCode != 200) throw Exception(response.body);

    final body = jsonDecode(response.body);

    switch (currency) {
      case Currency.eur:
        return BigInt.from(body['eur'] * 100);
      case Currency.chf:
        return BigInt.from(body['chf'] * 100);
    }
  }
}
