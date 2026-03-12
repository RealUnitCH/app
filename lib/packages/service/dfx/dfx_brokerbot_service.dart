import 'dart:convert';

import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/brokerbot/dfx_buy_price_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/brokerbot/dfx_shares_dto.dart';
import 'package:realunit_wallet/styles/currency.dart';

class DfxBrokerbotService {
  static const _buyPricePath = '/v1/realunit/brokerbot/buyPrice';
  static const _sharesPath = '/v1/realunit/brokerbot/shares';

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
}
