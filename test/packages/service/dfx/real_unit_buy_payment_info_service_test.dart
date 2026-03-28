import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/repository/cache_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_buy_payment_info_service.dart';

class MockApiConfig extends Mock implements ApiConfig {}

class MockCacheRepository extends Mock implements CacheRepository {}

class TestAppStore extends AppStore {
  final http.Client client;

  TestAppStore(this.client, ApiConfig Function() apiConfig) : super(apiConfig, MockCacheRepository());

  @override
  http.Client get httpClient => client;
}

void main() {
  late ApiConfig apiConfig;
  late RealUnitBuyPaymentInfoService service;

  setUp(() {
    apiConfig = MockApiConfig();
    when(() => apiConfig.apiHost).thenReturn('dev.api.dfx.swiss');
    when(() => apiConfig.networkMode).thenReturn(NetworkMode.testnet);
  });

  AppStore buildAppStore(Future<http.Response> Function(http.Request) handler) {
    final client = MockClient(handler);
    return TestAppStore(client, () => apiConfig)..dfxAuthToken = 'test-auth-token';
  }

  group('$RealUnitBuyPaymentInfoService', () {
    group('confirmPayment', () {
      test('sends PUT request to correct endpoint', () async {
        String? capturedUrl;
        String? capturedMethod;
        Map<String, String>? capturedHeaders;
        final referenceText = 'REALU-123';

        final appStore = buildAppStore((request) async {
          capturedUrl = request.url.toString();
          capturedMethod = request.method;
          capturedHeaders = request.headers;
          return http.Response('{"reference":"$referenceText"}', 200);
        });

        final paymentInfoId = 123;

        service = RealUnitBuyPaymentInfoService(appStore);
        final reference = await service.confirmPayment(paymentInfoId);

        expect(capturedMethod, equals('PUT'));
        expect(capturedUrl, contains(apiConfig.apiHost));
        expect(capturedUrl, contains('/v1/realunit/buy/$paymentInfoId/confirm'));
        expect(capturedHeaders?['Authorization'], equals('Bearer test-auth-token'));
        expect(reference, equals(referenceText));
      });

      test('throws exception on non-200/201 status code', () async {
        final appStore = buildAppStore(
          (request) async => http.Response('{"error": "Not found"}', 404),
        );

        final service = RealUnitBuyPaymentInfoService(appStore);

        expect(
          () => service.confirmPayment(999),
          throwsA(isA<Exception>()),
        );
      });

      test('succeeds on 200 status code', () async {
        final referenceText = 'REALU-123';
        final appStore = buildAppStore(
          (request) async => http.Response('{"reference":"$referenceText"}', 200),
        );
        service = RealUnitBuyPaymentInfoService(appStore);

        final reference = await service.confirmPayment(1);
        expect(reference, equals(referenceText));
      });

      test('succeeds on 201 status code', () async {
        final referenceText = 'REALU-123';
        final appStore = buildAppStore(
          (request) async => http.Response('{"reference":"$referenceText"}', 201),
        );
        service = RealUnitBuyPaymentInfoService(appStore);

        final reference = await service.confirmPayment(1);
        expect(reference, equals(referenceText));
      });
    });
  });
}
