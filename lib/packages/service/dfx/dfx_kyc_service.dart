import 'dart:convert';

import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_financial_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_level_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_session_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/user_dto.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';
import 'package:realunit_wallet/styles/language.dart';

class DfxKycService extends DFXAuthService {
  static const _userPath = '/v2/user';
  static const _kycPath = 'v2/kyc';

  String get _host => appStore.apiConfig.apiHost;

  DfxKycService(super.appStore);

  @override
  AWalletAccount get wallet => appStore.wallet.currentAccount;

  @override
  String get walletAddress => wallet.primaryAddress.address.hexEip55;

  Future<UserDto> getUser() async {
    final authToken = appStore.dfxAuthToken;

    final uri = buildUri(_host, _userPath);
    var response = await appStore.httpClient.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode == 401) {
      final newToken = await refreshAuthToken();
      response = await appStore.httpClient.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $newToken',
        },
      );
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson);
    }

    final json = jsonDecode(response.body);
    return UserDto.fromJson(json);
  }

  Future<KycLevelDto> getKycStatus() async {
    final user = await getUser();
    final authToken = appStore.dfxAuthToken;

    final uri = buildUri(_host, _kycPath);
    final response = await appStore.httpClient.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-kyc-code': user.kyc.hash,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson);
    }

    final json = jsonDecode(response.body);
    return KycLevelDto.fromJson(json);
  }

  Future<KycSessionDto> continueKyc() async {
    final user = await getUser();
    final authToken = appStore.dfxAuthToken;

    final uri = buildUri(_host, _kycPath);
    final response = await appStore.httpClient.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-kyc-code': user.kyc.hash,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson);
    }

    final json = jsonDecode(response.body);
    return KycSessionDto.fromJson(json);
  }

  Future<KycSessionDto> startStep(KycStepName stepName) async {
    final user = await getUser();
    final authToken = appStore.dfxAuthToken;

    final uri = buildUri(_host, '$_kycPath/${stepName.value}');
    final response = await appStore.httpClient.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-kyc-code': user.kyc.hash,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson);
    }

    final json = jsonDecode(response.body);
    return KycSessionDto.fromJson(json);
  }

  Future<void> updateUser(Map<String, dynamic> body) async {
    final authToken = appStore.dfxAuthToken;

    final uri = buildUri(_host, _userPath);
    final response = await appStore.httpClient.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson);
    }
  }

  /// similar to `updateUser()` but is used to set/update data of a user by using the provided session url from `startStep()` or `continueKyc()`
  Future<void> setData(String url, Map<String, dynamic> body) async {
    final user = await getUser();
    final authToken = appStore.dfxAuthToken;

    final uri = Uri.parse(url);
    final response = await appStore.httpClient.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-kyc-code': user.kyc.hash,
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson);
    }
    return;
  }

  Future<void> request2FaCode() async {
    final user = await getUser();
    final authToken = appStore.dfxAuthToken;

    final uri = buildUri(_host, '$_kycPath/2fa', {'level': 'Strict'});
    final response = await appStore.httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-kyc-code': user.kyc.hash,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson);
    }
    return;
  }

  Future<void> verify2FaCode(String code) async {
    final user = await getUser();
    final authToken = appStore.dfxAuthToken;

    final uri = buildUri(_host, '$_kycPath/2fa/verify');
    final response = await appStore.httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-kyc-code': user.kyc.hash,
      },
      body: jsonEncode({'token': code}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson);
    }
    return;
  }

  Future<KycFinancialOutData> getFinancialData(
    String url, {
    Language language = Language.de,
  }) async {
    final user = await getUser();
    final authToken = appStore.dfxAuthToken;

    final uri = Uri.parse('$url?lang=${language.code}');
    final response = await appStore.httpClient.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-kyc-code': user.kyc.hash,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson);
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return KycFinancialOutData.fromJson(json);
  }

  Future<void> setFinancialData(String url, List<KycFinancialResponse> responses) async {
    final user = await getUser();
    final authToken = appStore.dfxAuthToken;

    final uri = Uri.parse(url);
    final response = await appStore.httpClient.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-kyc-code': user.kyc.hash,
      },
      body: jsonEncode({
        'responses': responses.map((r) => r.toJson()).toList(),
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson);
    }
  }
}
