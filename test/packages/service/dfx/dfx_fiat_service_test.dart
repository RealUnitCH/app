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
import 'package:realunit_wallet/packages/service/dfx/dfx_fiat_service.dart';

class _MockAppStore extends Mock implements AppStore {}

const _chf = {
  'id': 1,
  'name': 'CHF',
  'buyable': true,
  'sellable': true,
};
const _eur = {
  'id': 2,
  'name': 'EUR',
  'buyable': true,
  'sellable': false,
};

void main() {
  late _MockAppStore appStore;

  setUp(() {
    appStore = _MockAppStore();
    when(() => appStore.apiConfig)
        .thenReturn(const ApiConfig(networkMode: NetworkMode.mainnet));
  });

  DfxFiatService build(http.Client client) {
    when(() => appStore.httpClient).thenReturn(client);
    return DfxFiatService(appStore);
  }

  group('$DfxFiatService', () {
    test('getAllFiats maps the DTO list and caches the result', () async {
      var callCount = 0;
      final client = MockClient((request) async {
        callCount++;
        expect(request.url.path, '/v1/fiat');
        return http.Response(jsonEncode([_chf, _eur]), 200);
      });
      final service = build(client);

      final first = await service.getAllFiats();
      final second = await service.getAllFiats();

      expect(first, hasLength(2));
      expect(first.map((f) => f.name), ['CHF', 'EUR']);
      expect(first.firstWhere((f) => f.name == 'EUR').sellable, isFalse);
      expect(callCount, 1);
      expect(identical(first, second), isTrue);
    });

    test('getAllFiats throws on a non-200 response', () async {
      final client = MockClient((_) async => http.Response('boom', 500));
      final service = build(client);

      expect(() => service.getAllFiats(), throwsException);
    });

    test('invalidateCache forces the next call to refetch', () async {
      var callCount = 0;
      final client = MockClient((request) async {
        callCount++;
        return http.Response(jsonEncode([_chf]), 200);
      });
      final service = build(client);

      await service.getAllFiats();
      await service.getAllFiats();
      expect(callCount, 1, reason: 'second call within TTL must hit the cache');

      service.invalidateCache();
      await service.getAllFiats();
      expect(
        callCount,
        2,
        reason: 'after invalidateCache the next call must hit the network',
      );
    });

    test('cache refreshes after the 5-minute TTL elapses', () {
      // Beweist, dass die TTL wirklich greift (nicht nur invalidateCache).
      // Mid-Session-Backend-Änderungen an buyable/sellable müssen ohne
      // App-Restart sichtbar werden — sonst sind Compliance-Stops blind.
      fakeAsync((async) {
        var callCount = 0;
        final client = MockClient((_) async {
          callCount++;
          return http.Response(jsonEncode([_chf]), 200);
        });
        final service = build(client);

        unawaited(service.getAllFiats());
        async.flushMicrotasks();
        expect(callCount, 1);

        async.elapse(const Duration(minutes: 4, seconds: 59));
        unawaited(service.getAllFiats());
        async.flushMicrotasks();
        expect(
          callCount,
          1,
          reason: 'within 5-min TTL the cache must still be served',
        );

        async.elapse(const Duration(seconds: 2));
        unawaited(service.getAllFiats());
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
