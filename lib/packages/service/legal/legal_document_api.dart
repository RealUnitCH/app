import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:realunit_wallet/packages/config/network_mode.dart';

const legalApiTimeout = Duration(seconds: 3);

typedef LegalGet = Future<http.Response> Function(Uri uri);

String legalApiHost(NetworkMode mode) =>
    mode.isTestnet ? 'dev.api.realunit.app' : 'api.realunit.app';

/// Reads `markdown` from `GET /v1/legal/{id}/{lang}`. Returns null when the
/// response is missing, blank, or the call fails. The caller keeps the
/// bundled asset in that case.
Future<String?> loadLegalMarkdown({
  required String host,
  required String id,
  required String lang,
  required LegalGet get,
  Duration timeout = legalApiTimeout,
}) async {
  try {
    final uri = Uri.https(host, '/v1/legal/$id/$lang');
    final response = await get(uri).timeout(timeout);
    if (response.statusCode != 200) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) return null;
    final markdown = decoded['markdown'];
    if (markdown is! String || markdown.trim().isEmpty) return null;
    return markdown;
  } catch (_) {
    return null;
  }
}
