import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_company_info_service.dart';

class _MockAppStore extends Mock implements AppStore {}

const _realUnit = {
  'brand': 'RealUnit',
  'name': 'RealUnit Schweiz AG',
  'phone': '+41 41 761 00 90',
  'email': 'info@realunit.ch',
  'website': 'realunit.ch',
  'address': {
    'street': 'Schochenmühlestrasse 6',
    'zip': '6340',
    'city': 'Baar',
    'country': 'CH',
  },
};

void main() {
  late _MockAppStore appStore;

  setUp(() {
    appStore = _MockAppStore();
    when(() => appStore.apiConfig)
        .thenReturn(const ApiConfig(networkMode: NetworkMode.mainnet));
  });

  DfxCompanyInfoService build(http.Client client) {
    when(() => appStore.httpClient).thenReturn(client);
    return DfxCompanyInfoService(appStore);
  }

  group('$DfxCompanyInfoService', () {
    test('parses the response and caches by brand (case-insensitive)', () async {
      var callCount = 0;
      final client = MockClient((request) async {
        callCount++;
        expect(request.url.path, '/v1/company-info/RealUnit');
        return http.Response(jsonEncode(_realUnit), 200);
      });
      final service = build(client);

      final info = await service.getForBrand('RealUnit');
      await service.getForBrand('realunit'); // case-insensitive cache hit

      expect(info.brand, 'RealUnit');
      expect(info.address?.country, 'CH');
      expect(callCount, 1);
    });

    test('throws on a non-200 response', () async {
      final client = MockClient((_) async => http.Response('not found', 404));
      final service = build(client);

      expect(() => service.getForBrand('Unknown'), throwsException);
    });

    test('handles a payload without an address block', () async {
      final client = MockClient((_) async => http.Response(
            jsonEncode({'brand': 'X', 'name': 'X AG'}),
            200,
          ));
      final service = build(client);

      final info = await service.getForBrand('X');

      expect(info.brand, 'X');
      expect(info.address, isNull);
    });
  });
}
