import 'dart:convert';

import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/wallet/real_unit_wallet_status_dto.dart';

class RealUnitWalletService extends DFXAuthService {
  RealUnitWalletService(super.appStore, super.walletService);

  static const _walletStatusPath = '/v1/realunit/wallet/status';

  Future<RealUnitWalletStatusDto> getWalletStatus() async {
    final uri = buildUri(host, _walletStatusPath);
    final response = await authenticatedGet(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson, httpStatusCode: response.statusCode);
    }

    return RealUnitWalletStatusDto.fromJson(jsonDecode(response.body));
  }
}
