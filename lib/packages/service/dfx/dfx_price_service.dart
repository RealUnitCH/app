import 'dart:convert';

import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/models/price_point.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/price_service.dart';
import 'package:realunit_wallet/styles/currency.dart';

const String _pricingHistoryEndpoint =
    "https://dev.api.dfx.swiss/v1/realunit/price/history?timeFrame=ALL";
const String _pricingEndpoint = "https://dev.api.dfx.swiss/v1/realunit/price";

class DFXPriceService extends APriceService {
  final AppStore _appStore;

  DFXPriceService(this._appStore);

  @override
  Future<List<PricePoint>> getPriceChart(Asset asset, Currency currency) async {
    final response =
        await _appStore.httpClient.get(Uri.parse(_pricingHistoryEndpoint));

    if (response.statusCode != 200) throw Exception(response.body);

    final body = jsonDecode(response.body) as List;

    final result = <PricePoint>[];

    for (final entry in body) {
      BigInt price;
      switch (currency) {
        case Currency.eur:
          price = BigInt.from(entry["eur"] * 100);
          break;
        case Currency.chf:
          price = BigInt.from(entry["chf"] * 100);
          break;
      }
      result.add(PricePoint(
        asset: asset,
        price: price,
        time: DateTime.parse(entry["timestamp"]),
      ));
    }

    return result;
  }

  @override
  Future<BigInt> getPriceOfAsset(Asset asset, Currency currency) async {
    final response =
        await _appStore.httpClient.get(Uri.parse(_pricingEndpoint));

    if (response.statusCode != 200) throw Exception(response.body);

    final body = jsonDecode(response.body);

    switch (currency) {
      case Currency.eur:
        return BigInt.from(body["eur"] * 100);
      case Currency.chf:
        return BigInt.from(body["chf"] * 100);
    }
  }
}
