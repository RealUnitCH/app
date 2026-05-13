import 'dart:convert';

import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/brokerbot/dfx_buy_price_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/brokerbot/dfx_buy_shares_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/brokerbot/dfx_sell_price_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/brokerbot/dfx_sell_shares_dto.dart';
import 'package:realunit_wallet/styles/currency.dart';

class DfxBrokerbotService {
  static const _buyPricePath = '/v1/realunit/brokerbot/buyPrice';
  static const _buySharesPath = '/v1/realunit/brokerbot/buyShares';
  static const _sellPricePath = '/v1/realunit/brokerbot/sellPrice';
  static const _sellSharesPath = '/v1/realunit/brokerbot/sellShares';

  String get _host => _appStore.apiConfig.apiHost;

  final AppStore _appStore;

  DfxBrokerbotService(this._appStore);

  /// Convert REALU shares → CHF
  Future<BrokerbotBuyPriceDto> getBuyPrice(String sharesInput, Currency currency) async {
    final shares = int.tryParse(sharesInput);
    if (shares == null || shares <= 0) {
      throw Exception('BuyPrice request failed: sharesInput is not valid');
    }

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
  Future<BrokerbotBuySharesDto> getBuyShares(String amountInput, Currency currency) async {
    final amount = double.tryParse(amountInput);
    if (amount == null || amount <= 0) {
      throw Exception('Shares request failed: amountInput is not valid');
    }

    final uri = buildUri(_host, _buySharesPath, {
      'amount': amount.toString(),
      'currency': currency.code,
    });
    final res = await _appStore.httpClient.get(uri);

    if (res.statusCode != 200) {
      throw Exception('Shares request failed: ${res.body}');
    }

    return BrokerbotBuySharesDto.fromJson(jsonDecode(res.body));
  }

  /// Convert REALU shares → CHF (with fees)
  Future<BrokerbotSellPriceDto> getSellPrice(String sharesInput, Currency currency) async {
    final shares = int.tryParse(sharesInput);
    if (shares == null || shares <= 0) {
      throw Exception('SellPrice request failed: sharesInput is invalid');
    }

    final authToken = _appStore.sessionCache.authToken;
    final uri = buildUri(_host, _sellPricePath, {
      'shares': shares.toString(),
      'currency': currency.code,
    });
    final res = await _appStore.httpClient.get(
      uri,
      headers: {'Authorization': 'Bearer $authToken'},
    );

    if (res.statusCode != 200) {
      final errorJson = jsonDecode(res.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson, httpStatusCode: res.statusCode);
    }

    return BrokerbotSellPriceDto.fromJson(jsonDecode(res.body));
  }

  /// Convert CHF → REALU shares (with fees)
  Future<BrokerbotSellSharesDto> getSellShares(String amountInput, Currency currency) async {
    final amount = double.tryParse(amountInput);
    if (amount == null || amount <= 0) {
      throw Exception('SellShares request failed: amountInput is invalid');
    }

    final authToken = _appStore.sessionCache.authToken;
    final uri = buildUri(_host, _sellSharesPath, {
      'amount': amount.toString(),
      'currency': currency.code,
    });
    final res = await _appStore.httpClient.get(
      uri,
      headers: {'Authorization': 'Bearer $authToken'},
    );

    if (res.statusCode != 200) {
      final errorJson = jsonDecode(res.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson, httpStatusCode: res.statusCode);
    }

    return BrokerbotSellSharesDto.fromJson(jsonDecode(res.body));
  }
}
