import 'dart:convert';

import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/faucet/faucet_response_dto.dart';

class DfxFaucetService extends DFXAuthService {
  static const _faucetPath = 'v1/faucet';

  DfxFaucetService(super.appStore);

  Future<FaucetResponseDto> requestFaucet() async {
    final uri = buildUri(host, _faucetPath);
    final response = await authenticatedPost(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return FaucetResponseDto.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }

    final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
    throw ApiException.fromJson(errorJson, httpStatusCode: response.statusCode);
  }
}
