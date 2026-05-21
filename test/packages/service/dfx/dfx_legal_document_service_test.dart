import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_legal_document_service.dart';

class _MockAppStore extends Mock implements AppStore {}

const _agreementDe = {
  'id': 1,
  'type': 'RegistrationAgreement',
  'language': 'de',
  'version': '1.0',
  'url': 'https://realunit.ch/de.pdf',
};
const _agreementEn = {
  'id': 2,
  'type': 'RegistrationAgreement',
  'language': 'en',
  'version': '1.0',
  'url': 'https://realunit.ch/en.pdf',
};
const _dfxTerms = {
  'id': 3,
  'type': 'DfxTerms',
  'language': null,
  'version': '1.0',
  'url': 'https://docs.dfx.swiss/en/terms.html',
};

void main() {
  late _MockAppStore appStore;

  setUp(() {
    appStore = _MockAppStore();
    when(() => appStore.apiConfig)
        .thenReturn(const ApiConfig(networkMode: NetworkMode.mainnet));
  });

  DfxLegalDocumentService build(http.Client client) {
    when(() => appStore.httpClient).thenReturn(client);
    return DfxLegalDocumentService(appStore);
  }

  group('$DfxLegalDocumentService', () {
    test('passes type + language as query parameters and parses the response', () async {
      Uri? captured;
      final client = MockClient((request) async {
        captured = request.url;
        return http.Response(jsonEncode([_agreementDe]), 200);
      });
      final service = build(client);

      final docs = await service.getDocuments(type: 'RegistrationAgreement', language: 'de');

      expect(docs, hasLength(1));
      expect(docs.first.url, 'https://realunit.ch/de.pdf');
      expect(captured!.path, '/v1/legal-document');
      expect(captured!.queryParameters['type'], 'RegistrationAgreement');
      expect(captured!.queryParameters['language'], 'de');
    });

    test('caches identical queries and only hits the network once', () async {
      var callCount = 0;
      final client = MockClient((_) async {
        callCount++;
        return http.Response(jsonEncode([_agreementDe]), 200);
      });
      final service = build(client);

      await service.getDocuments(type: 'RegistrationAgreement', language: 'de');
      await service.getDocuments(type: 'RegistrationAgreement', language: 'de');

      expect(callCount, 1);
    });

    test('treats different filter shapes as different cache keys', () async {
      var callCount = 0;
      final client = MockClient((_) async {
        callCount++;
        return http.Response(jsonEncode([_agreementEn]), 200);
      });
      final service = build(client);

      await service.getDocuments(type: 'RegistrationAgreement', language: 'de');
      await service.getDocuments(type: 'RegistrationAgreement', language: 'en');

      expect(callCount, 2);
    });

    test('returns language-agnostic documents (language=null) verbatim', () async {
      final client = MockClient((_) async => http.Response(jsonEncode([_dfxTerms]), 200));
      final service = build(client);

      final docs = await service.getDocuments(type: 'DfxTerms');

      expect(docs.first.language, isNull);
      expect(docs.first.url, 'https://docs.dfx.swiss/en/terms.html');
    });

    test('throws on a non-200 response', () async {
      final client = MockClient((_) async => http.Response('boom', 500));
      final service = build(client);

      expect(() => service.getDocuments(), throwsException);
    });
  });
}
