import 'dart:convert';

import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/faucet/faucet_response_dto.dart';

class DfxFaucetService {
  static const _faucetPath = 'v1/faucet';

  String get _host => _appStore.apiConfig.apiHost;

  final AppStore _appStore;

  DfxFaucetService(AppStore appStore) : _appStore = appStore;

  Future<FaucetResponseDto> requestFaucet() async {
    final authToken = _appStore.sessionCache.authToken;
    final uri = buildUri(_host, _faucetPath);
    final response = await _appStore.httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return FaucetResponseDto.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }

    final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
    throw ApiException.fromJson(errorJson, httpStatusCode: response.statusCode);
  }
}
