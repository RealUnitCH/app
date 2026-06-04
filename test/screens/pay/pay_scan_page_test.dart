import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/lnurl_decoder.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_pay_service.dart';
import 'package:realunit_wallet/screens/pay/cubits/pay_scan/pay_scan_cubit.dart';
import 'package:realunit_wallet/screens/pay/pay_quote_page.dart';
import 'package:realunit_wallet/screens/pay/pay_scan_page.dart';

import '../../helper/helper.dart';

class _MockPayScanCubit extends MockCubit<PayScanState> implements PayScanCubit {}

class _MockPayService extends Mock implements RealUnitPayService {}

void main() {
  late _MockPayScanCubit scanCubit;

  setUpAll(() {
    // pay_scan_page.dart carries the `@no-integration-test` note: the live
    // camera is exercised only on a real device. The stub keeps the headless
    // preview deterministic and free of MissingPluginException.
    stubMobileScannerChannel();

    // The decoded-link navigation pushes PayQuotePage, which resolves the pay
    // service from getIt and triggers a load(); register a mock so the pushed
    // route builds. The load is gated off via an unsupported environment so no
    // network is touched.
    final payService = _MockPayService();
    when(() => payService.isPaySupportedEnvironment).thenReturn(false);
    GetIt.instance.registerSingleton<RealUnitPayService>(payService);
  });

  tearDownAll(() async => GetIt.instance.reset());

  setUp(() {
    scanCubit = _MockPayScanCubit();
    when(() => scanCubit.state).thenReturn(const PayScanScanning());
    when(() => scanCubit.reset()).thenReturn(null);
  });

  Widget buildSubject() => BlocProvider<PayScanCubit>.value(
    value: scanCubit,
    child: const PayScanView(),
  );

  group('$PayScanPage', () {
    testWidgets('builds its own cubit and renders $PayScanView', (tester) async {
      await tester.pumpApp(const PayScanPage());

      expect(find.byType(PayScanView), findsOne);
    });
  });

  group('$PayScanView', () {
    testWidgets('renders the scan title and the scanner preview', (tester) async {
      await tester.pumpApp(buildSubject());

      expect(find.text(S.current.payScanTitle), findsOne);
      expect(find.byType(MobileScanner), findsOne);
    });

    testWidgets('onDetect forwards a scanned raw value to the cubit', (tester) async {
      when(() => scanCubit.onCodeDetected(any())).thenReturn(null);

      await tester.pumpApp(buildSubject());

      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
      // A capture with no barcodes is ignored (rawValue is null) …
      scanner.onDetect!(const BarcodeCapture());
      // … while a barcode with a raw value is forwarded to the cubit.
      scanner.onDetect!(
        const BarcodeCapture(barcodes: [Barcode(rawValue: 'lnurl_raw')]),
      );

      verify(() => scanCubit.onCodeDetected('lnurl_raw')).called(1);
    });

    testWidgets('an invalid scan shows a snackbar and resets the cubit', (tester) async {
      whenListen(
        scanCubit,
        Stream<PayScanState>.fromIterable([const PayScanInvalid('bad code')]),
        initialState: const PayScanScanning(),
      );

      await tester.pumpApp(buildSubject());
      await tester.pump();

      expect(find.byType(SnackBar), findsOne);
      expect(find.text(S.current.payScanInvalid), findsOne);
      verify(() => scanCubit.reset()).called(1);
    });

    testWidgets('a decoded link navigates to the quote step and resets the cubit', (tester) async {
      final link = DecodedPaymentLink(
        id: 'pl_abc123',
        lnurlpUrl: Uri.parse('https://api.dfx.swiss/v1/lnurlp/pl_abc123'),
      );
      whenListen(
        scanCubit,
        Stream<PayScanState>.fromIterable([PayScanDecoded(link)]),
        initialState: const PayScanScanning(),
      );

      await tester.pumpApp(buildSubject());
      await tester.pumpAndSettle();

      // The quote step is pushed and rendered; the cubit is reset so returning
      // to the scanner re-arms detection.
      expect(find.byType(PayQuoteView), findsOne);
      verify(() => scanCubit.reset()).called(1);
    });
  });
}
