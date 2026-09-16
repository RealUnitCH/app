import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_wallet_features_service.dart';

class _MockAppStore extends Mock implements AppStore {}

void main() {
  late _MockAppStore appStore;

  setUp(() {
    appStore = _MockAppStore();
    when(() => appStore.apiConfig)
        .thenReturn(const ApiConfig(networkMode: NetworkMode.mainnet));
  });

  RealUnitWalletFeaturesService build(http.Client client) {
    when(() => appStore.httpClient).thenReturn(client);
    return RealUnitWalletFeaturesService(appStore);
  }

  group('$RealUnitWalletFeaturesService', () {
    test('get maps JSON true flags from GET /v1/app/realunit/wallet-features', () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'api.dfx.swiss');
        expect(request.url.path, '/v1/app/realunit/wallet-features');
        return http.Response(
          jsonEncode({
            'pay': true,
            'send': false,
            'promoCode': true,
            'referral': false,
          }),
          200,
        );
      });

      final dto = await build(client).get();

      expect(dto.pay, isTrue);
      expect(dto.send, isFalse);
      expect(dto.promoCode, isTrue);
      expect(dto.referral, isFalse);
    });

    test('get throws on a non-200 response', () async {
      final client = MockClient((_) async => http.Response('boom', 500));

      await expectLater(build(client).get(), throwsA(isA<Exception>()));
    });

    test('get throws when the body is not a JSON object', () async {
      final client = MockClient(
        (_) async => http.Response(jsonEncode(['pay']), 200),
      );

      await expectLater(build(client).get(), throwsA(isA<Exception>()));
    });
  });
}
