import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/config/dto/dfx_config_dto.dart';

/// Fetches the API's authoritative input validation patterns from
/// `GET /v1/config`.
///
/// The app validates name/address fields against the pattern the API serves
/// instead of hardcoding a copy of the `swissPaymentText` regex. The server
/// keeps re-validating authoritatively (`@IsSwissPaymentText()`), so this is
/// purely for instant inline UX — never a gate the backend doesn't also
/// enforce.
///
/// The compiled pattern is cached in memory so form validators can run
/// synchronously ([isSwissPaymentText]); a TTL lets mid-session backend
/// changes surface without an app restart.
class DfxConfigService {
  static const _configPath = '/v1/config';

  /// How long a fetched config stays cached before the next call refetches.
  /// The pattern changes only on a backend deploy, so a generous TTL is fine.
  static const _cacheTtl = Duration(minutes: 30);

  DfxConfigDto? _cached;
  DateTime? _cachedAt;
  RegExp? _swissPaymentText;

  final AppStore _appStore;

  String get _host => _appStore.apiConfig.apiHost;

  DfxConfigService(AppStore appStore) : _appStore = appStore;

  Future<DfxConfigDto> getConfig() async {
    final cached = _cached;
    final cachedAt = _cachedAt;
    if (cached != null && cachedAt != null && clock.now().difference(cachedAt) < _cacheTtl) {
      return cached;
    }

    final uri = buildUri(_host, _configPath);
    final response = await _appStore.httpClient.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch config: ${response.statusCode}');
    }

    final config = DfxConfigDto.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    _cached = config;
    _cachedAt = clock.now();
    _swissPaymentText = config.formats.swissPaymentText.toRegExp();
    return config;
  }

  /// Warms the in-memory cache so [isSwissPaymentText] can validate
  /// synchronously. Safe to call eagerly at startup; failures are the
  /// caller's concern (the validator degrades gracefully if unloaded).
  Future<void> load() => getConfig();

  /// Returns `true` if [value] is accepted by the API's `swissPaymentText`
  /// pattern. Empty/null is valid (callers chain a non-empty check).
  ///
  /// If the pattern has not loaded yet, returns `true` (does not block) — the
  /// server re-validates authoritatively, so the app is never *more*
  /// restrictive than the API and never needs a hardcoded fallback copy.
  bool isSwissPaymentText(String? value) {
    if (value == null || value.isEmpty) return true;
    final pattern = _swissPaymentText;
    if (pattern == null) return true;
    return pattern.hasMatch(value);
  }

  /// Drops the in-memory cache so the next [getConfig]/[load] refetches.
  /// Intended for explicit invalidation points (e.g. network switch).
  void invalidateCache() {
    _cached = null;
    _cachedAt = null;
    _swissPaymentText = null;
  }
}
