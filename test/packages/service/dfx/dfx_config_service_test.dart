import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_config_service.dart';

class _MockAppStore extends Mock implements AppStore {}

/// The authoritative `swissPaymentText` pattern as served by the API
/// (`GET /v1/config`). Kept as a raw string so the backslash escapes reach
/// Dart's `RegExp` verbatim — exactly what the app receives over the wire.
const _swissPaymentTextPattern = r'^[\x20-\x7EÀÁÂÄÇÈÉÊËÌÍÎÏÑÒÓÔÖÙÚÛÜÝàáâäçèéêëìíîïñòóôöùúûüýß\n]*$';

String _configBody({String pattern = _swissPaymentTextPattern, String flags = 'u'}) {
  return jsonEncode({
    'formats': {
      'swissPaymentText': {'pattern': pattern, 'flags': flags},
    },
  });
}

void main() {
  late _MockAppStore appStore;

  setUp(() {
    appStore = _MockAppStore();
    when(() => appStore.apiConfig).thenReturn(const ApiConfig(networkMode: NetworkMode.mainnet));
  });

  DfxConfigService build(http.Client client) {
    when(() => appStore.httpClient).thenReturn(client);
    return DfxConfigService(appStore);
  }

  group('$DfxConfigService', () {
    test('load fetches /v1/config and caches the result', () async {
      var callCount = 0;
      final client = MockClient((request) async {
        callCount++;
        expect(request.url.path, '/v1/config');
        return http.Response(_configBody(), 200);
      });
      final service = build(client);

      await service.load();
      await service.load();

      expect(callCount, 1, reason: 'second load should hit the in-memory cache');
    });

    test('invalidateCache forces a refetch and clears the compiled pattern', () async {
      var callCount = 0;
      final client = MockClient((_) async {
        callCount++;
        return http.Response(_configBody(), 200);
      });
      final service = build(client);

      await service.load();
      expect(service.isSwissPaymentText('王小明'), isFalse);

      service.invalidateCache();
      // pattern dropped -> defers to server again until reloaded
      expect(service.isSwissPaymentText('王小明'), isTrue);

      await service.load();
      expect(callCount, 2, reason: 'cache was invalidated, so load refetched');
    });

    test('throws when the backend responds non-200', () async {
      final client = MockClient((_) async => http.Response('nope', 500));
      final service = build(client);

      expect(service.load(), throwsException);
    });

    group('isSwissPaymentText before the pattern is loaded', () {
      test('returns true so the app never blocks input the server may accept', () {
        final service = build(MockClient((_) async => http.Response(_configBody(), 200)));

        // Even input the loaded pattern would reject passes pre-load — the
        // server re-validates authoritatively.
        expect(service.isSwissPaymentText('王小明'), isTrue);
        expect(service.isSwissPaymentText('Müller'), isTrue);
      });
    });

    group('isSwissPaymentText after loading the API pattern', () {
      late DfxConfigService service;

      setUp(() async {
        service = build(MockClient((_) async => http.Response(_configBody(), 200)));
        await service.load();
      });

      test('empty / null are valid (callers chain a non-empty check)', () {
        expect(service.isSwissPaymentText(null), isTrue);
        expect(service.isSwissPaymentText(''), isTrue);
      });

      test('plain ASCII, digits and punctuation pass', () {
        expect(service.isSwissPaymentText('Bahnhofstrasse 1'), isTrue);
        expect(service.isSwissPaymentText("It's @ #1 / 50%."), isTrue);
      });

      test('foreign alphanumeric postal codes pass (the bug this fixes)', () {
        expect(service.isSwissPaymentText('1011 AB'), isTrue); // NL
        expect(service.isSwissPaymentText('EC1A 1BB'), isTrue); // UK
        expect(service.isSwissPaymentText('K1A 0B1'), isTrue); // CA
        expect(service.isSwissPaymentText('D02 AF30'), isTrue); // IE
      });

      test('Swiss national-language diacritics pass', () {
        expect(service.isSwissPaymentText('Zürich'), isTrue);
        expect(service.isSwissPaymentText('Genève'), isTrue);
        expect(service.isSwissPaymentText('François'), isTrue);
        expect(service.isSwissPaymentText('ÄÖÜß'), isTrue);
      });

      test('newline allowed, tab and carriage return rejected', () {
        expect(service.isSwissPaymentText('Line 1\nLine 2'), isTrue);
        expect(service.isSwissPaymentText('a\tb'), isFalse);
        expect(service.isSwissPaymentText('a\rb'), isFalse);
      });

      test('non-Latin scripts and emoji are rejected', () {
        expect(service.isSwissPaymentText('王小明'), isFalse);
        expect(service.isSwissPaymentText('Иван'), isFalse);
        expect(service.isSwissPaymentText('Hello 👋'), isFalse);
      });

      test('diacritics outside the Swiss set are rejected', () {
        expect(service.isSwissPaymentText('Łódź'), isFalse);
        expect(service.isSwissPaymentText('São Paulo'), isFalse);
        expect(service.isSwissPaymentText('Tromsø'), isFalse);
        expect(service.isSwissPaymentText('Müllеr'), isFalse, reason: 'Cyrillic е (U+0435)');
      });
    });

    test('applies whatever pattern the API serves, not a hardcoded copy', () async {
      // A deliberately different server pattern: digits only. The service must
      // honour it verbatim — proving the rule lives in the API, not the client.
      final service = build(
        MockClient((_) async => http.Response(_configBody(pattern: r'^[0-9]*$', flags: ''), 200)),
      );
      await service.load();

      expect(service.isSwissPaymentText('12345'), isTrue);
      expect(
        service.isSwissPaymentText('Zürich'),
        isFalse,
        reason: 'letters rejected by this server pattern',
      );
    });
  });
}
