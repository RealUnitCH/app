import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/walletconnect/walletconnect_scan_page.dart';

import '../../../helper/helper.dart';

class _MockWalletConnectScanCubit extends MockCubit<WalletConnectScanState>
    implements WalletConnectScanCubit {}

void main() {
  late _MockWalletConnectScanCubit scanCubit;

  setUpAll(() {
    // The QR scanner is camera-coupled (mobile_scanner). The stub answers the
    // permission handshake so the preview settles into its deterministic
    // placeholder state instead of throwing MissingPluginException — the live
    // camera carries the `@no-integration-test` note on walletconnect_scan_page.dart.
    stubMobileScannerChannel();
  });

  setUp(() {
    scanCubit = _MockWalletConnectScanCubit();
    when(() => scanCubit.state).thenReturn(const WalletConnectScanScanning());
  });

  group('$WalletConnectScanView', () {
    goldenTest(
      'scanning state with camera preview placeholder',
      fileName: 'walletconnect_scan_page_scanning',
      constraints: phoneConstraints,
      // The camera preview never reaches an `isInitialized` frame headlessly,
      // so pumpAndSettle (default in precacheImages) would await a settle that
      // never comes. pumpOnce captures the deterministic placeholder frame.
      pumpBeforeTest: pumpOnce,
      builder: () => wrapForGolden(
        BlocProvider<WalletConnectScanCubit>.value(
          value: scanCubit,
          child: const WalletConnectScanView(),
        ),
      ),
    );
  });
}
