import 'dart:convert';

import 'package:realunit_wallet/models/portfolio_value_point.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/account/dto/account_summary_dto.dart';
import 'package:realunit_wallet/styles/currency.dart';

class RealUnitAccountService {
  static String _accountSummaryPath(String address) => '/v1/realunit/account/$address';

  String get _host => _appStore.apiConfig.apiHost;

  final AppStore _appStore;

  RealUnitAccountService(AppStore appStore) : _appStore = appStore;

  Future<List<PortfolioValuePoint>> getPortfolioHistory(Currency currency) async {
    final address = _appStore.wallet.currentAccount.primaryAddress.address.hexEip55;
    final uri = buildUri(_host, _accountSummaryPath(address));
    final response = await _appStore.httpClient.get(uri);

    if (response.statusCode != 200) throw Exception(response.body);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final accountSummary = AccountSummaryDto.fromJson(body);

    return accountSummary.historicalBalances.map((h) {
      final value = switch (currency) {
        Currency.chf => h.valueChf,
        Currency.eur => h.valueEur,
      };
      return PortfolioValuePoint(
        value: BigInt.from((value ?? 0) * 100),
        balance: BigInt.parse(h.balance),
        time: h.timestamp,
      );
    }).toList();
  }
}
