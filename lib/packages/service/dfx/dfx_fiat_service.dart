import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/fiat/dto/dfx_fiat_dto.dart';

/// Fetches the list of fiats from `GET /v1/fiat`.
///
/// The result is cached in memory for [_cacheTtl] so the picker can render
/// synchronously, but the TTL guarantees that mid-session backend changes
/// to `buyable` / `sellable` become visible without an app restart (relevant
/// for compliance stops, currency maintenance, etc.).
class DfxFiatService {
  static const _fiatPath = '/v1/fiat';

  /// How long a fetched fiat list stays cached before the next call refetches.
  static const _cacheTtl = Duration(minutes: 5);

  List<DfxFiatDto>? _cachedFiats;
  DateTime? _cachedAt;

  final AppStore _appStore;

  String get _host => _appStore.apiConfig.apiHost;

  DfxFiatService(AppStore appStore) : _appStore = appStore;

  Future<List<DfxFiatDto>> getAllFiats() async {
    final cached = _cachedFiats;
    final cachedAt = _cachedAt;
    if (cached != null && cachedAt != null && clock.now().difference(cachedAt) < _cacheTtl) {
      return cached;
    }

    final uri = buildUri(_host, _fiatPath);
    final response = await _appStore.httpClient.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch fiats: ${response.statusCode}');
    }

    final List<dynamic> jsonList = jsonDecode(response.body);
    final fiats = jsonList.map((json) => DfxFiatDto.fromJson(json)).toList();
    _cachedFiats = fiats;
    _cachedAt = clock.now();
    return fiats;
  }

  /// Drops the in-memory cache so the next [getAllFiats] call refetches.
  /// Intended for explicit invalidation points (e.g. logout, network switch).
  void invalidateCache() {
    _cachedFiats = null;
    _cachedAt = null;
  }
}
