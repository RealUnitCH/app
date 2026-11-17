import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/service/legal/legal_document_api.dart';

void main() {
  test('legalApiHost follows the network mode', () {
    expect(legalApiHost(NetworkMode.mainnet), 'api.realunit.app');
    expect(legalApiHost(NetworkMode.testnet), 'dev.api.realunit.app');
  });

  test('loadLegalMarkdown returns the markdown field', () async {
    final text = await loadLegalMarkdown(
      host: 'api.realunit.app',
      id: 'privacy_policy',
      lang: 'de',
      get: (uri) async {
        expect(
          uri,
          Uri.https('api.realunit.app', '/v1/legal/privacy_policy/de'),
        );
        return http.Response('{"markdown":"# Hallo"}', 200);
      },
    );
    expect(text, '# Hallo');
  });

  test('loadLegalMarkdown returns null for a non-200 response', () async {
    final text = await loadLegalMarkdown(
      host: 'api.realunit.app',
      id: 'privacy_policy',
      lang: 'de',
      get: (_) async => http.Response('missing', 404),
    );
    expect(text, isNull);
  });

  test(
    'loadLegalMarkdown returns null when the body is not an object',
    () async {
      final text = await loadLegalMarkdown(
        host: 'api.realunit.app',
        id: 'privacy_policy',
        lang: 'de',
        get: (_) async => http.Response('[]', 200),
      );
      expect(text, isNull);
    },
  );

  test('loadLegalMarkdown returns null when markdown is not text', () async {
    final text = await loadLegalMarkdown(
      host: 'api.realunit.app',
      id: 'privacy_policy',
      lang: 'de',
      get: (_) async => http.Response('{"markdown":1}', 200),
    );
    expect(text, isNull);
  });

  test('loadLegalMarkdown returns null when markdown is blank', () async {
    final text = await loadLegalMarkdown(
      host: 'api.realunit.app',
      id: 'privacy_policy',
      lang: 'de',
      get: (_) async => http.Response('{"markdown":"  "}', 200),
    );
    expect(text, isNull);
  });

  test('loadLegalMarkdown returns null when the call throws', () async {
    final text = await loadLegalMarkdown(
      host: 'api.realunit.app',
      id: 'privacy_policy',
      lang: 'de',
      get: (_) async => throw Exception('down'),
    );
    expect(text, isNull);
  });

  test('loadLegalMarkdown returns null when the body is not JSON', () async {
    final text = await loadLegalMarkdown(
      host: 'api.realunit.app',
      id: 'privacy_policy',
      lang: 'de',
      get: (_) async => http.Response('{', 200),
    );
    expect(text, isNull);
  });

  test('loadLegalMarkdown returns null when the call times out', () async {
    final text = await loadLegalMarkdown(
      host: 'api.realunit.app',
      id: 'privacy_policy',
      lang: 'de',
      timeout: const Duration(milliseconds: 20),
      get: (_) => Completer<http.Response>().future,
    );
    expect(text, isNull);
  });
}
