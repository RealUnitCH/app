import 'dart:convert';

import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';

class DfxBlockchainApiService {
  static const _balancesPath = 'v1/blockchain/balances';

  String get _host => _appStore.apiConfig.apiHost;

  String get _blockchain => _appStore.apiConfig.asset.chainId == 1 ? 'Ethereum' : 'Sepolia';

  final AppStore _appStore;

  DfxBlockchainApiService(AppStore appStore) : _appStore = appStore;

  Future<double> getEthBalance(String address) async {
    final authToken = _appStore.sessionCache.authToken;
    final uri = buildUri(_host, _balancesPath);
    final response = await _appStore.httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'address': address,
        'blockchain': _blockchain,
        'assetIds': [_appStore.apiConfig.ethAssetId],
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to get balances: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final balances = json['balances'] as List<dynamic>;
    if (balances.isEmpty) return 0.0;
    return ((balances.first as Map<String, dynamic>)['balance'] as num).toDouble();
  }
}
