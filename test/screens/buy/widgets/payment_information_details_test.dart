import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_buy_payment_info_service.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_information_details.dart';
import 'package:realunit_wallet/styles/currency.dart';

import '../../../helper/helper.dart';

class MockRealUnitBuyPaymentInfoService extends Mock
    implements RealUnitBuyPaymentInfoService {}

void main() {
  late MockRealUnitBuyPaymentInfoService mockService;

  const testPaymentInfo = BuyPaymentInfo(
    id: 123,
    iban: 'CH1234567890',
    bic: 'TESTBIC',
    name: 'Test Name',
    street: 'Test Street',
    number: '42',
    zip: '8000',
    city: 'Zurich',
    country: 'CH',
    currency: Currency.chf,
  );

  setUp(() {
    mockService = MockRealUnitBuyPaymentInfoService();

    final getIt = GetIt.instance;
    if (getIt.isRegistered<RealUnitBuyPaymentInfoService>()) {
      getIt.unregister<RealUnitBuyPaymentInfoService>();
    }
    getIt.registerSingleton<RealUnitBuyPaymentInfoService>(mockService);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Widget buildSubject() {
    return const Scaffold(
      body: SingleChildScrollView(
        child: PaymentInformationDetails(
          buyPaymentInfo: testPaymentInfo,
          amount: '100.00',
        ),
      ),
    );
  }

  group('PaymentInformationDetails', () {
    testWidgets('displays payment info correctly', (tester) async {
      await tester.pumpApp(buildSubject());

      expect(find.text('CH1234567890'), findsOneWidget);
      expect(find.text('TESTBIC'), findsOneWidget);
      expect(find.text('Test Name'), findsOneWidget);
      expect(find.text('Test Street 42'), findsOneWidget);
      expect(find.text('8000'), findsOneWidget);
      expect(find.text('Zurich'), findsOneWidget);
      expect(find.text('CH'), findsOneWidget);
    });

    testWidgets('shows loading indicator when confirming', (tester) async {
      // Use a future that never completes to keep loading state
      when(() => mockService.confirmPayment(123)).thenAnswer(
        (_) => Completer<void>().future,
      );

      await tester.pumpApp(buildSubject());

      // Scroll to make button visible
      await tester.dragUntilVisible(
        find.byType(FilledButton),
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );

      final button = find.byType(FilledButton);
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Button should be disabled during loading
      final filledButton = tester.widget<FilledButton>(button);
      expect(filledButton.onPressed, isNull);
    });

    testWidgets('calls confirmPayment with correct id on button tap',
        (tester) async {
      // Use a future that never completes to avoid triggering modal bottom sheet
      when(() => mockService.confirmPayment(123)).thenAnswer(
        (_) => Completer<void>().future,
      );

      await tester.pumpApp(buildSubject());

      // Scroll to make button visible
      await tester.dragUntilVisible(
        find.byType(FilledButton),
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );

      final button = find.byType(FilledButton);
      await tester.tap(button);
      await tester.pump();

      // Verify API was called with correct ID
      verify(() => mockService.confirmPayment(123)).called(1);
    });

    testWidgets('shows error snackbar on API failure', (tester) async {
      when(() => mockService.confirmPayment(123)).thenThrow(
        Exception('Network error'),
      );

      await tester.pumpApp(buildSubject());

      // Scroll to make button visible
      await tester.dragUntilVisible(
        find.byType(FilledButton),
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );

      final button = find.byType(FilledButton);
      await tester.tap(button);
      await tester.pumpAndSettle();

      // Should show error in snackbar
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Error'), findsOneWidget);
    });

    testWidgets('re-enables button after error', (tester) async {
      when(() => mockService.confirmPayment(123)).thenThrow(
        Exception('Network error'),
      );

      await tester.pumpApp(buildSubject());

      // Scroll to make button visible
      await tester.dragUntilVisible(
        find.byType(FilledButton),
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );

      final button = find.byType(FilledButton);
      await tester.tap(button);
      await tester.pumpAndSettle();

      // Button should be enabled again after error
      final filledButton = tester.widget<FilledButton>(button);
      expect(filledButton.onPressed, isNotNull);

      // Loading indicator should be gone
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
