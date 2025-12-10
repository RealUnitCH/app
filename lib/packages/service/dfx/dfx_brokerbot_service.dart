import 'dart:convert';

import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/brokerbot/dfx_buy_price_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/brokerbot/dfx_shares_dto.dart';

class DfxBrokerbotService {
  static const _baseUrl = "https://dev.api.dfx.swiss/v1/realunit/brokerbot";
  final AppStore _appStore;

  DfxBrokerbotService(this._appStore);

  /// Convert REALU shares → CHF
  Future<BrokerbotBuyPriceDto> getBuyPrice(int shares) async {
    final url = Uri.parse("$_baseUrl/buyPrice?shares=$shares");
    final res = await _appStore.httpClient.get(url);

    if (res.statusCode != 200) {
      throw Exception("BuyPrice request failed: ${res.body}");
    }

    return BrokerbotBuyPriceDto.fromJson(jsonDecode(res.body));
  }

  /// Convert CHF → REALU shares
  Future<BrokerbotSharesDto> getShares(double amount) async {
    final url = Uri.parse("$_baseUrl/shares?amount=$amount");
    final res = await _appStore.httpClient.get(url);

    if (res.statusCode != 200) {
      throw Exception("Shares request failed: ${res.body}");
    }

    return BrokerbotSharesDto.fromJson(jsonDecode(res.body));
  }
}
