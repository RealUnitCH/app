import 'dart:convert';

import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';

class DfxBlockchainApiService extends DFXAuthService {
  static const _balancesPath = 'v1/blockchain/balances';

  String get _blockchain => appStore.apiConfig.asset.chainId == 1 ? 'Ethereum' : 'Sepolia';

  DfxBlockchainApiService(super.appStore, super.walletService);

  Future<double> getEthBalance(String address) async {
    final uri = buildUri(host, _balancesPath);
    final response = await authenticatedPost(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'address': address,
        'blockchain': _blockchain,
        'assetIds': [appStore.apiConfig.ethAssetId],
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson, httpStatusCode: response.statusCode);
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final balances = json['balances'] as List<dynamic>;
    if (balances.isEmpty) return 0.0;
    return ((balances.first as Map<String, dynamic>)['balance'] as num).toDouble();
  }
}
