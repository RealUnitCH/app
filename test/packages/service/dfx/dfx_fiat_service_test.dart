import 'dart:convert';

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
  });
}
