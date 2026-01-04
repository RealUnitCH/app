import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/repository/settings_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_brokerbot_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_buy_payment_info_service.dart';
import 'package:realunit_wallet/screens/buy/buy_page.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/styles/currency.dart';
import 'package:realunit_wallet/styles/themes.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockSettingsRepository settingsRepository;
  late MockClient mockHttpClient;
  late _TestAppStore appStore;

  setUpAll(() {
    registerFallbackValue(Currency.chf);
  });

  setUp(() {
    settingsRepository = MockSettingsRepository();
    when(() => settingsRepository.language).thenReturn('de');
    when(() => settingsRepository.currency).thenReturn('CHF');
    when(() => settingsRepository.networkMode).thenReturn(NetworkMode.testnet);
    when(() => settingsRepository.apiConfig)
        .thenReturn(const ApiConfig(networkMode: NetworkMode.testnet));
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Widget buildTestApp({required Widget child}) {
    return MaterialApp(
      theme: realUnitTheme,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      locale: const Locale('de'),
      home: child,
    );
  }

  group('Buy Flow E2E Tests', () {
    testWidgets('Complete buy flow: enter amount → view payment info → confirm',
        (tester) async {
      // Setup mock HTTP client for successful flow
      mockHttpClient = MockClient((request) async {
        final url = request.url.toString();

        // Mock brokerbot price API
        if (url.contains('brokerbot')) {
          return http.Response(
            jsonEncode({
              'price': '1.50',
              'shares': '200',
            }),
            200,
          );
        }

        // Mock payment info API - GET
        if (url.contains('/v1/buy/paymentInfos') && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'id': 123,
              'iban': 'CH93 0076 2011 6238 5295 7',
              'bic': 'UBSWCHZH80A',
              'name': 'DFX AG',
              'street': 'Bahnhofstrasse',
              'number': '10',
              'zip': '6300',
              'city': 'Zug',
              'country': 'CH',
              'currency': 'CHF',
            }),
            200,
          );
        }

        // Mock payment confirmation API - PUT
        if (url.contains('/v1/buy/paymentInfos/123/confirm') &&
            request.method == 'PUT') {
          return http.Response('{}', 200);
        }

        return http.Response('Not Found', 404);
      });

      appStore = _TestAppStore(mockHttpClient);
      appStore.settingsRepository = settingsRepository;
      appStore.dfxAuthToken = 'test-token';

      final getIt = GetIt.instance;
      getIt.registerSingleton<AppStore>(appStore);
      getIt.registerSingleton<SettingsBloc>(SettingsBloc(settingsRepository));
      getIt.registerSingleton<DfxBrokerbotService>(DfxBrokerbotService(appStore));
      getIt.registerSingleton<RealUnitBuyPaymentInfoService>(
        RealUnitBuyPaymentInfoService(appStore),
      );

      await tester.pumpWidget(buildTestApp(child: const BuyPage()));
      await tester.pumpAndSettle();

      // Verify we're on the buy page
      expect(find.text('REALU kaufen'), findsOneWidget);

      // Wait for initial data to load
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Find amount input field and enter value
      final amountField = find.byType(TextField).first;
      await tester.enterText(amountField, '500');
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Verify payment information is displayed
      expect(find.text('CH93 0076 2011 6238 5295 7'), findsOneWidget);
      expect(find.text('UBSWCHZH80A'), findsOneWidget);
      expect(find.text('DFX AG'), findsOneWidget);

      // Scroll to confirm button if needed
      await tester.dragUntilVisible(
        find.byType(FilledButton).last,
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );

      // Tap confirm button
      final confirmButton = find.byType(FilledButton).last;
      await tester.tap(confirmButton);
      await tester.pump();

      // Verify loading indicator appears
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for API call to complete
      await tester.pumpAndSettle(const Duration(seconds: 1));
    });

    testWidgets('Buy flow shows registration required when not registered',
        (tester) async {
      // Setup mock HTTP client that returns registration required error
      mockHttpClient = MockClient((request) async {
        final url = request.url.toString();

        // Mock brokerbot price API
        if (url.contains('brokerbot')) {
          return http.Response(
            jsonEncode({
              'price': '1.50',
              'shares': '200',
            }),
            200,
          );
        }

        // Mock payment info API - return 403 for registration required
        if (url.contains('/v1/buy/paymentInfos')) {
          return http.Response(
            jsonEncode({
              'statusCode': 403,
              'message': 'User data missing',
            }),
            403,
          );
        }

        return http.Response('Not Found', 404);
      });

      appStore = _TestAppStore(mockHttpClient);
      appStore.settingsRepository = settingsRepository;
      appStore.dfxAuthToken = 'test-token';

      final getIt = GetIt.instance;
      getIt.registerSingleton<AppStore>(appStore);
      getIt.registerSingleton<SettingsBloc>(SettingsBloc(settingsRepository));
      getIt.registerSingleton<DfxBrokerbotService>(DfxBrokerbotService(appStore));
      getIt.registerSingleton<RealUnitBuyPaymentInfoService>(
        RealUnitBuyPaymentInfoService(appStore),
      );

      await tester.pumpWidget(buildTestApp(child: const BuyPage()));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify registration required message is shown
      expect(find.text('Registrierung erforderlich'), findsOneWidget);
    });

    testWidgets('Buy flow shows KYC required when KYC level insufficient',
        (tester) async {
      // Setup mock HTTP client that returns KYC required error
      mockHttpClient = MockClient((request) async {
        final url = request.url.toString();

        // Mock brokerbot price API
        if (url.contains('brokerbot')) {
          return http.Response(
            jsonEncode({
              'price': '1.50',
              'shares': '200',
            }),
            200,
          );
        }

        // Mock payment info API - return 403 for KYC required
        if (url.contains('/v1/buy/paymentInfos')) {
          return http.Response(
            jsonEncode({
              'statusCode': 403,
              'message': 'KYC level required',
            }),
            403,
          );
        }

        return http.Response('Not Found', 404);
      });

      appStore = _TestAppStore(mockHttpClient);
      appStore.settingsRepository = settingsRepository;
      appStore.dfxAuthToken = 'test-token';

      final getIt = GetIt.instance;
      getIt.registerSingleton<AppStore>(appStore);
      getIt.registerSingleton<SettingsBloc>(SettingsBloc(settingsRepository));
      getIt.registerSingleton<DfxBrokerbotService>(DfxBrokerbotService(appStore));
      getIt.registerSingleton<RealUnitBuyPaymentInfoService>(
        RealUnitBuyPaymentInfoService(appStore),
      );

      await tester.pumpWidget(buildTestApp(child: const BuyPage()));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify KYC required message is shown
      expect(find.text('Identitätsprüfung erforderlich'), findsOneWidget);
    });

    testWidgets('Buy flow handles API error gracefully', (tester) async {
      // Setup mock HTTP client that returns server error
      mockHttpClient = MockClient((request) async {
        final url = request.url.toString();

        // Mock brokerbot price API
        if (url.contains('brokerbot')) {
          return http.Response(
            jsonEncode({
              'price': '1.50',
              'shares': '200',
            }),
            200,
          );
        }

        // Mock payment info API - success
        if (url.contains('/v1/buy/paymentInfos') && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'id': 123,
              'iban': 'CH93 0076 2011 6238 5295 7',
              'bic': 'UBSWCHZH80A',
              'name': 'DFX AG',
              'street': 'Bahnhofstrasse',
              'number': '10',
              'zip': '6300',
              'city': 'Zug',
              'country': 'CH',
              'currency': 'CHF',
            }),
            200,
          );
        }

        // Mock confirmation API - return 500
        if (url.contains('/v1/buy/paymentInfos/123/confirm')) {
          return http.Response('Internal Server Error', 500);
        }

        return http.Response('Not Found', 404);
      });

      appStore = _TestAppStore(mockHttpClient);
      appStore.settingsRepository = settingsRepository;
      appStore.dfxAuthToken = 'test-token';

      final getIt = GetIt.instance;
      getIt.registerSingleton<AppStore>(appStore);
      getIt.registerSingleton<SettingsBloc>(SettingsBloc(settingsRepository));
      getIt.registerSingleton<DfxBrokerbotService>(DfxBrokerbotService(appStore));
      getIt.registerSingleton<RealUnitBuyPaymentInfoService>(
        RealUnitBuyPaymentInfoService(appStore),
      );

      await tester.pumpWidget(buildTestApp(child: const BuyPage()));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Scroll to confirm button
      await tester.dragUntilVisible(
        find.byType(FilledButton).last,
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );

      // Tap confirm button
      final confirmButton = find.byType(FilledButton).last;
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Verify error snackbar appears
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Error'), findsOneWidget);

      // Button should be re-enabled after error
      final filledButton = tester.widget<FilledButton>(confirmButton);
      expect(filledButton.onPressed, isNotNull);
    });

    testWidgets('Buy flow currency conversion updates dynamically',
        (tester) async {
      int priceCallCount = 0;

      // Setup mock HTTP client with dynamic price responses
      mockHttpClient = MockClient((request) async {
        final url = request.url.toString();

        // Mock brokerbot price API with different responses
        if (url.contains('brokerbot')) {
          priceCallCount++;
          final amount = priceCallCount == 1 ? '200' : '666';
          return http.Response(
            jsonEncode({
              'price': '1.50',
              'shares': amount,
            }),
            200,
          );
        }

        // Mock payment info API
        if (url.contains('/v1/buy/paymentInfos') && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'id': 123,
              'iban': 'CH93 0076 2011 6238 5295 7',
              'bic': 'UBSWCHZH80A',
              'name': 'DFX AG',
              'street': 'Bahnhofstrasse',
              'number': '10',
              'zip': '6300',
              'city': 'Zug',
              'country': 'CH',
              'currency': 'CHF',
            }),
            200,
          );
        }

        return http.Response('Not Found', 404);
      });

      appStore = _TestAppStore(mockHttpClient);
      appStore.settingsRepository = settingsRepository;
      appStore.dfxAuthToken = 'test-token';

      final getIt = GetIt.instance;
      getIt.registerSingleton<AppStore>(appStore);
      getIt.registerSingleton<SettingsBloc>(SettingsBloc(settingsRepository));
      getIt.registerSingleton<DfxBrokerbotService>(DfxBrokerbotService(appStore));
      getIt.registerSingleton<RealUnitBuyPaymentInfoService>(
        RealUnitBuyPaymentInfoService(appStore),
      );

      await tester.pumpWidget(buildTestApp(child: const BuyPage()));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Initial amount should be 300 (default)
      final amountField = find.byType(TextField).first;

      // Change amount
      await tester.enterText(amountField, '1000');
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Verify that the conversion was triggered (multiple API calls)
      expect(priceCallCount, greaterThan(1));
    });
  });
}

class _TestAppStore extends AppStore {
  final http.Client _client;

  _TestAppStore(this._client);

  @override
  http.Client get httpClient => _client;
}
