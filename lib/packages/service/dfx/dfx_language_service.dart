import 'dart:convert';

import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/language/dto/dfx_language_dto.dart';

class DfxLanguageService {
  static const _languagePath = '/v1/language';

  List<DfxLanguageDto>? _cachedLanguages;

  final AppStore _appStore;

  String get _host => _appStore.apiConfig.apiHost;

  DfxLanguageService(AppStore appStore) : _appStore = appStore;

  Future<List<DfxLanguageDto>> getAllLanguages() async {
    if (_cachedLanguages != null) return _cachedLanguages!;

    final uri = buildUri(_host, _languagePath);
    final response = await _appStore.httpClient.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch languages: ${response.statusCode}');
    }

    final List<dynamic> jsonList = jsonDecode(response.body);
    final languages = jsonList
        .map((json) => DfxLanguageDto.fromJson(json))
        .toList();
    _cachedLanguages = languages;
    return languages;
  }
}
