import 'dart:convert';

import 'package:http/http.dart';
import 'package:realunit_wallet/generated/release_info.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/client_policy/dto/real_unit_client_policy_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/client_policy/real_unit_client_policy.dart';

/// Unauthenticated `GET /v1/realunit/client-policy`. Fail-open: any non-200,
/// timeout, transport, or parse failure returns null and never throws.
class RealUnitClientPolicyService {
  static const Duration policyGetTimeout = Duration(seconds: 5);
  static const _policyPath = '/v1/realunit/client-policy';

  final AppStore _appStore;
  final Client _httpClient;
  final String Function() _installedVersion;

  RealUnitClientPolicyService(
    this._appStore, {
    String Function()? installedVersion,
    Client? httpClient,
  })  : _httpClient = httpClient ?? _appStore.httpClient,
        _installedVersion = installedVersion ?? (() => releaseMarketingVersion);

  String get _host => _appStore.apiConfig.apiHost;

  Future<RealUnitClientPolicy?> fetch() async {
    try {
      final uri = buildUri(_host, _policyPath);
      final response = await _httpClient.get(uri).timeout(policyGetTimeout);
      if (response.statusCode != 200) return null;
      final map = _decodeObject(response.body);
      if (map == null) return null;
      return RealUnitClientPolicyDto.fromJson(map)
          .toDomain(installed: _installedVersion());
    } catch (_) {
      return null;
    }
  }
}

Map<String, dynamic>? _decodeObject(String body) {
  final decoded = jsonDecode(body);
  if (decoded is Map) {
    return decoded.map((k, v) => MapEntry(k.toString(), v));
  }
  return null;
}
