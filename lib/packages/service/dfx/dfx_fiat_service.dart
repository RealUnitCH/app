import 'dart:convert';

import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/fiat/dto/dfx_fiat_dto.dart';

class DfxFiatService {
  static const _fiatPath = '/v1/fiat';

  List<DfxFiatDto>? _cachedFiats;

  final AppStore _appStore;

  String get _host => _appStore.apiConfig.apiHost;

  DfxFiatService(AppStore appStore) : _appStore = appStore;

  Future<List<DfxFiatDto>> getAllFiats() async {
    if (_cachedFiats != null) return _cachedFiats!;

    final uri = buildUri(_host, _fiatPath);
    final response = await _appStore.httpClient.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch fiats: ${response.statusCode}');
    }

    final List<dynamic> jsonList = jsonDecode(response.body);
    final fiats = jsonList.map((json) => DfxFiatDto.fromJson(json)).toList();
    _cachedFiats = fiats;
    return fiats;
  }
}
