import 'dart:convert';

import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/legal_document/dto/dfx_legal_document_dto.dart';

class DfxLegalDocumentService {
  static const _legalDocumentPath = '/v1/legal-document';

  // Cache key: `${type ?? '*'}:${language ?? '*'}` — same scheme as the
  // server-side cache so repeated identical queries share results.
  final Map<String, List<DfxLegalDocumentDto>> _cache = {};

  final AppStore _appStore;

  String get _host => _appStore.apiConfig.apiHost;

  DfxLegalDocumentService(AppStore appStore) : _appStore = appStore;

  Future<List<DfxLegalDocumentDto>> getDocuments({String? type, String? language}) async {
    final key = '${type ?? '*'}:${language ?? '*'}';
    final cached = _cache[key];
    if (cached != null) return cached;

    final queryParams = <String, String>{};
    if (type != null) queryParams['type'] = type;
    if (language != null) queryParams['language'] = language;

    final uri = buildUri(_host, _legalDocumentPath).replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final response = await _appStore.httpClient.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch legal documents: ${response.statusCode}');
    }

    final List<dynamic> jsonList = jsonDecode(response.body);
    final documents = jsonList
        .map((json) => DfxLegalDocumentDto.fromJson(json as Map<String, dynamic>))
        .toList();
    _cache[key] = documents;
    return documents;
  }
}
