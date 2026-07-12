import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
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

    test('invalidateCache forces the next call to refetch', () async {
      var callCount = 0;
      final client = MockClient((request) async {
        callCount++;
        return http.Response(jsonEncode([_en]), 200);
      });
      final service = build(client);

      await service.getAllLanguages();
      await service.getAllLanguages();
      expect(callCount, 1, reason: 'second call within TTL must hit the cache');

      service.invalidateCache();
      await service.getAllLanguages();
      expect(
        callCount,
        2,
        reason: 'after invalidateCache the next call must hit the network',
      );
    });

    test('cache refreshes after the 5-minute TTL elapses', () {
      // Beweist, dass die TTL wirklich greift (nicht nur invalidateCache).
      // Mid-Session-Backend-Änderungen an `enable` müssen ohne App-Restart
      // sichtbar werden — sonst kann eine deaktivierte Sprache weiter
      // wählbar bleiben.
      fakeAsync((async) {
        var callCount = 0;
        final client = MockClient((_) async {
          callCount++;
          return http.Response(jsonEncode([_en]), 200);
        });
        final service = build(client);

        unawaited(service.getAllLanguages());
        async.flushMicrotasks();
        expect(callCount, 1);

        async.elapse(const Duration(minutes: 4, seconds: 59));
        unawaited(service.getAllLanguages());
        async.flushMicrotasks();
        expect(
          callCount,
          1,
          reason: 'within 5-min TTL the cache must still be served',
        );

        async.elapse(const Duration(seconds: 2));
        unawaited(service.getAllLanguages());
        async.flushMicrotasks();
        expect(
          callCount,
          2,
          reason: 'past the 5-min TTL the next call must refetch',
        );
      });
    });
  });
}
