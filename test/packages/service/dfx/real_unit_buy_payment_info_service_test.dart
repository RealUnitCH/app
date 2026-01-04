import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/repository/settings_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_buy_payment_info_service.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late AppStore appStore;
  late MockSettingsRepository settingsRepository;

  setUp(() {
    settingsRepository = MockSettingsRepository();
    when(() => settingsRepository.networkMode).thenReturn(NetworkMode.testnet);
    when(() => settingsRepository.apiConfig)
        .thenReturn(const ApiConfig(networkMode: NetworkMode.testnet));

    appStore = AppStore();
    appStore.settingsRepository = settingsRepository;
    appStore.dfxAuthToken = 'test-auth-token';
  });

  group('RealUnitBuyPaymentInfoService', () {
    group('confirmPayment', () {
      test('sends PUT request to correct endpoint', () async {
        String? capturedUrl;
        String? capturedMethod;
        Map<String, String>? capturedHeaders;

        final mockClient = MockClient((request) async {
          capturedUrl = request.url.toString();
          capturedMethod = request.method;
          capturedHeaders = request.headers;
          return http.Response('{}', 200);
        });

        final testAppStore = _TestAppStore(mockClient);
        testAppStore.settingsRepository = settingsRepository;
        testAppStore.dfxAuthToken = 'test-auth-token';

        final service = RealUnitBuyPaymentInfoService(testAppStore);
        await service.confirmPayment(123);

        expect(capturedMethod, equals('PUT'));
        expect(capturedUrl, contains('dev.api.dfx.swiss'));
        expect(capturedUrl, contains('/v1/buy/paymentInfos/123/confirm'));
        expect(capturedHeaders?['Authorization'], equals('Bearer test-auth-token'));
      });

      test('throws exception on non-200/201 status code', () async {
        final mockClient = MockClient((request) async {
          return http.Response('{"error": "Not found"}', 404);
        });

        final testAppStore = _TestAppStore(mockClient);
        testAppStore.settingsRepository = settingsRepository;
        testAppStore.dfxAuthToken = 'test-auth-token';

        final service = RealUnitBuyPaymentInfoService(testAppStore);

        expect(
          () => service.confirmPayment(999),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to confirm payment: 404'),
          )),
        );
      });

      test('succeeds on 200 status code', () async {
        final mockClient = MockClient((request) async {
          return http.Response('{}', 200);
        });

        final testAppStore = _TestAppStore(mockClient);
        testAppStore.settingsRepository = settingsRepository;
        testAppStore.dfxAuthToken = 'test-auth-token';

        final service = RealUnitBuyPaymentInfoService(testAppStore);

        await expectLater(service.confirmPayment(1), completes);
      });

      test('succeeds on 201 status code', () async {
        final mockClient = MockClient((request) async {
          return http.Response('{}', 201);
        });

        final testAppStore = _TestAppStore(mockClient);
        testAppStore.settingsRepository = settingsRepository;
        testAppStore.dfxAuthToken = 'test-auth-token';

        final service = RealUnitBuyPaymentInfoService(testAppStore);

        await expectLater(service.confirmPayment(1), completes);
      });
    });

  });
}

class _TestAppStore extends AppStore {
  final http.Client _client;

  _TestAppStore(this._client);

  @override
  http.Client get httpClient => _client;
}
