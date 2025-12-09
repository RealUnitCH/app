import 'dart:convert';

import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/dfx_allowlist_status.dart';

class DfxAllowlistService {
  static const _baseUrl = "https://dev.api.dfx.swiss/v1/realunit";
  final AppStore _appStore;

  DfxAllowlistService(this._appStore);

  Future<DfxAllowlistStatus> checkAllowlist() async {
    final url = Uri.parse("$_baseUrl/allowlist/${_appStore.primaryAddress}");
    final response = await _appStore.httpClient.get(url);

    if (response.statusCode != 200) {
      throw Exception("Allowlist request failed: ${response.body}");
    }

    return DfxAllowlistStatus.fromJson(jsonDecode(response.body));
  }
}
