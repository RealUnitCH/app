import 'dart:convert';

import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/company_info/dto/dfx_company_info_dto.dart';

class DfxCompanyInfoService {
  static const _basePath = '/v1/company-info';

  final Map<String, DfxCompanyInfoDto> _cache = {};

  final AppStore _appStore;

  String get _host => _appStore.apiConfig.apiHost;

  DfxCompanyInfoService(AppStore appStore) : _appStore = appStore;

  Future<DfxCompanyInfoDto> getForBrand(String brand) async {
    final key = brand.toLowerCase();
    final cached = _cache[key];
    if (cached != null) return cached;

    final uri = buildUri(_host, '$_basePath/$brand');
    final response = await _appStore.httpClient.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch company info for "$brand": ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final info = DfxCompanyInfoDto.fromJson(json);
    _cache[key] = info;
    return info;
  }
}
