import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_language_service.dart';

class _MockAppStore extends Mock implements AppStore {}

const _en = {
  'id': 1,
  'symbol': 'EN',
  'name': 'English',
  'foreignName': 'English',
  'enable': true,
};
const _de = {
  'id': 2,
  'symbol': 'DE',
  'name': 'German',
  'foreignName': 'Deutsch',
  'enable': true,
};
const _fr = {
  'id': 3,
  'symbol': 'FR',
  'name': 'French',
  'foreignName': 'Français',
  'enable': false,
};

void main() {
  late _MockAppStore appStore;

  setUp(() {
    appStore = _MockAppStore();
    when(() => appStore.apiConfig)
        .thenReturn(const ApiConfig(networkMode: NetworkMode.mainnet));
  });

  DfxLanguageService build(http.Client client) {
    when(() => appStore.httpClient).thenReturn(client);
    return DfxLanguageService(appStore);
  }

  group('$DfxLanguageService', () {
    test('getAllLanguages maps the DTO list and caches', () async {
      var callCount = 0;
      final client = MockClient((request) async {
        callCount++;
        expect(request.url.path, '/v1/language');
        return http.Response(jsonEncode([_en, _de, _fr]), 200);
      });
      final service = build(client);

      final first = await service.getAllLanguages();
      final second = await service.getAllLanguages();

      expect(first, hasLength(3));
      expect(first.map((l) => l.symbol), ['EN', 'DE', 'FR']);
      expect(first.firstWhere((l) => l.symbol == 'FR').enable, isFalse);
      expect(callCount, 1);
      expect(identical(first, second), isTrue);
    });

    test('getAllLanguages throws on a non-200 response', () async {
      final client = MockClient((_) async => http.Response('boom', 500));
      final service = build(client);

      expect(() => service.getAllLanguages(), throwsException);
    });
  });
}
