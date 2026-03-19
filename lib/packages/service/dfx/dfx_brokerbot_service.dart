import 'dart:convert';

import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/brokerbot/dfx_buy_price_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/brokerbot/dfx_sell_price_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/brokerbot/dfx_sell_shares_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/brokerbot/dfx_shares_dto.dart';
import 'package:realunit_wallet/styles/currency.dart';

class DfxBrokerbotService {
  static const _buyPricePath = '/v1/realunit/brokerbot/buyPrice';
  static const _sharesPath = '/v1/realunit/brokerbot/shares';
  static const _sellPricePath = '/v1/realunit/brokerbot/sellPrice';
  static const _sellSharesPath = '/v1/realunit/brokerbot/sellShares';

  String get _host => _appStore.apiConfig.apiHost;

  final AppStore _appStore;

  DfxBrokerbotService(this._appStore);

  /// Convert REALU shares → CHF
  Future<BrokerbotBuyPriceDto> getBuyPrice(int shares, Currency currency) async {
    final uri = buildUri(_host, _buyPricePath, {
      'shares': shares.toString(),
      'currency': currency.code,
    });
    final res = await _appStore.httpClient.get(uri);

    if (res.statusCode != 200) {
      throw Exception('BuyPrice request failed: ${res.body}');
    }

    return BrokerbotBuyPriceDto.fromJson(jsonDecode(res.body));
  }

  /// Convert CHF → REALU shares
  Future<BrokerbotSharesDto> getShares(double amount, Currency currency) async {
    final uri = buildUri(_host, _sharesPath, {
      'amount': amount.toString(),
      'currency': currency.code,
    });
    final res = await _appStore.httpClient.get(uri);

    if (res.statusCode != 200) {
      throw Exception('Shares request failed: ${res.body}');
    }

    return BrokerbotSharesDto.fromJson(jsonDecode(res.body));
  }

  /// Convert REALU shares → CHF (with fees)
  Future<BrokerbotSellPriceDto> getSellPrice(int shares, Currency currency) async {
    final authToken = _appStore.dfxAuthToken;
    final uri = buildUri(_host, _sellPricePath, {
      'shares': shares.toString(),
      'currency': currency.code,
    });
    final res = await _appStore.httpClient.get(
      uri,
      headers: {'Authorization': 'Bearer $authToken'},
    );

    if (res.statusCode != 200) {
      throw Exception('SellPrice request failed: ${res.body}');
    }

    return BrokerbotSellPriceDto.fromJson(jsonDecode(res.body));
  }

  /// Convert target CHF → REALU shares needed (with fees)
  Future<BrokerbotSellSharesDto> getSellShares(double amount, Currency currency) async {
    final authToken = _appStore.dfxAuthToken;
    final uri = buildUri(_host, _sellSharesPath, {
      'amount': amount.toString(),
      'currency': currency.code,
    });
    final res = await _appStore.httpClient.get(
      uri,
      headers: {'Authorization': 'Bearer $authToken'},
    );

    if (res.statusCode != 200) {
      throw Exception('SellShares request failed: ${res.body}');
    }

    return BrokerbotSellSharesDto.fromJson(jsonDecode(res.body));
  }
}
