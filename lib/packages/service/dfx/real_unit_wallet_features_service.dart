import 'dart:convert';

import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/wallet_features/dto/real_unit_wallet_features_dto.dart';

class RealUnitWalletFeaturesService {
  static const _path = '/v1/app/realunit/wallet-features';

  final AppStore _appStore;

  String get _host => _appStore.apiConfig.apiHost;

  RealUnitWalletFeaturesService(AppStore appStore) : _appStore = appStore;

  Future<RealUnitWalletFeaturesDto> get() async {
    final uri = buildUri(_host, _path);
    final response = await _appStore.httpClient.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch wallet features: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Wallet features response is not a JSON object');
    }

    return RealUnitWalletFeaturesDto.fromJson(decoded);
  }
}
