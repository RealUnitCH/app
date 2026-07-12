import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';

class _MockAppStore extends Mock implements AppStore {}

const _ch = {
  'id': 41,
  'symbol': 'CH',
  'name': 'Switzerland',
  'foreignName': null,
  'locationAllowed': true,
  'ibanAllowed': true,
  'kycAllowed': true,
  'kycOrganizationAllowed': true,
  'nationalityAllowed': true,
  'bankAllowed': true,
  'cardAllowed': true,
  'cryptoAllowed': true,
};

const _de = {
  'id': 49,
  'symbol': 'DE',
  'name': 'Germany',
  'foreignName': 'Deutschland',
  'locationAllowed': true,
  'ibanAllowed': true,
  'kycAllowed': true,
  'kycOrganizationAllowed': true,
  'nationalityAllowed': true,
  'bankAllowed': true,
  'cardAllowed': true,
  'cryptoAllowed': true,
};

void main() {
  late _MockAppStore appStore;

  setUp(() {
    appStore = _MockAppStore();
    when(() => appStore.apiConfig)
        .thenReturn(const ApiConfig(networkMode: NetworkMode.mainnet));
  });

  DfxCountryService build(http.Client client) {
    when(() => appStore.httpClient).thenReturn(client);
    return DfxCountryService(appStore);
  }

  group('$DfxCountryService', () {
    test('getAllCountries maps the DTO list and caches the result', () async {
      var callCount = 0;
      final client = MockClient((request) async {
        callCount++;
        expect(request.url.path, '/v1/country');
        return http.Response(jsonEncode([_ch, _de]), 200);
      });
      final service = build(client);

      final first = await service.getAllCountries();
      final second = await service.getAllCountries();

      expect(first, hasLength(2));
      expect(first.map((c) => c.symbol), ['CH', 'DE']);
      expect(first.firstWhere((c) => c.symbol == 'DE').foreignName, 'Deutschland');
      // Second call must hit the cache, not the network.
      expect(callCount, 1);
      expect(identical(first, second), isTrue);
    });

    test('getAllCountries throws on a non-200 response', () async {
      final client = MockClient((_) async => http.Response('boom', 500));
      final service = build(client);

      expect(() => service.getAllCountries(), throwsException);
    });

    test('getCountryBySymbol matches case-insensitively', () async {
      final client = MockClient((_) async => http.Response(jsonEncode([_ch]), 200));
      final service = build(client);

      final byUpper = await service.getCountryBySymbol('CH');
      final byLower = await service.getCountryBySymbol('ch');

      expect(byUpper.id, 41);
      expect(byLower.id, 41);
    });

    test('getCountryBySymbol throws when the symbol is unknown', () async {
      final client = MockClient((_) async => http.Response(jsonEncode([_ch]), 200));
      final service = build(client);

      expect(() => service.getCountryBySymbol('XX'), throwsException);
    });

    test('cachedCountries field is populated after a successful fetch', () async {
      final client = MockClient((_) async => http.Response(jsonEncode([_ch]), 200));
      final service = build(client);

      expect(service.cachedCountries, isNull);
      await service.getAllCountries();
      expect(service.cachedCountries, isNotNull);
      expect(service.cachedCountries, hasLength(1));
    });
  });
}
