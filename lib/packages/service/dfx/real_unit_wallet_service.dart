import 'dart:convert';

import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/wallet/real_unit_wallet_status_dto.dart';

class RealUnitWalletService {
  RealUnitWalletService(AppStore appStore) : _appStore = appStore;

  static const _walletStatusPath = '/v1/realunit/wallet/status';

  final AppStore _appStore;

  String get _host => _appStore.apiConfig.apiHost;

  Future<RealUnitWalletStatusDto> getWalletStatus() async {
    final authToken = _appStore.sessionCache.authToken;

    final uri = buildUri(_host, _walletStatusPath);
    final response = await _appStore.httpClient.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode != 200) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson);
    }

    final dto = RealUnitWalletStatusDto.fromJson(jsonDecode(response.body));
    return dto;
  }
}
