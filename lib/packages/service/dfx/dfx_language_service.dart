import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/language/dto/dfx_language_dto.dart';

/// Fetches the list of languages from `GET /v1/language`.
///
/// The result is cached in memory for [_cacheTtl] so the picker can render
/// synchronously, but the TTL guarantees that mid-session backend changes
/// to `enable` become visible without an app restart.
class DfxLanguageService {
  static const _languagePath = '/v1/language';

  /// How long a fetched language list stays cached before the next call refetches.
  static const _cacheTtl = Duration(minutes: 5);

  List<DfxLanguageDto>? _cachedLanguages;
  DateTime? _cachedAt;

  final AppStore _appStore;

  String get _host => _appStore.apiConfig.apiHost;

  DfxLanguageService(AppStore appStore) : _appStore = appStore;

  Future<List<DfxLanguageDto>> getAllLanguages() async {
    final cached = _cachedLanguages;
    final cachedAt = _cachedAt;
    if (cached != null && cachedAt != null && clock.now().difference(cachedAt) < _cacheTtl) {
      return cached;
    }

    final uri = buildUri(_host, _languagePath);
    final response = await _appStore.httpClient.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch languages: ${response.statusCode}');
    }

    final jsonList = jsonDecode(response.body) as List<dynamic>;
    final languages = jsonList
        .map((json) => DfxLanguageDto.fromJson(json as Map<String, dynamic>))
        .toList();
    _cachedLanguages = languages;
    _cachedAt = clock.now();
    return languages;
  }

  /// Drops the in-memory cache so the next [getAllLanguages] call refetches.
  /// Intended for explicit invalidation points (e.g. logout, network switch).
  void invalidateCache() {
    _cachedLanguages = null;
    _cachedAt = null;
  }
}
