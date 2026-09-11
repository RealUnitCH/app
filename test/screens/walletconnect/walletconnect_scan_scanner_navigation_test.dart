import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:realunit_wallet/packages/walletconnect/walletconnect_engine.dart';
import 'package:realunit_wallet/packages/walletconnect/walletconnect_service.dart';
import 'package:realunit_wallet/screens/walletconnect/walletconnect_scan_page.dart';
import 'package:realunit_wallet/screens/walletconnect/walletconnect_session_page.dart';

import '../../helper/helper.dart';

const _pairing =
    'wc:00e46b69-d0cc-4b3e-b6a2-cee442f97188@2?relay-protocol=irn&symKey=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

class _FakeEngine implements WalletConnectEngine {
  final _events = StreamController<WalletConnectIncoming>.broadcast();

  @override
  Stream<WalletConnectIncoming> get events => _events.stream;

  @override
  Future<void> init({required String address, required List<int> chainIds}) async {}

  @override
  Future<void> pair(String uri) async {
    _events.add(
      const WalletConnectSessionProposal(
        proposalId: '1',
        originUrl: 'https://tokeninfo.aktionariat.com',
        verifyStatus: WalletConnectVerifyStatus.valid,
        proposerName: 'Aktionariat',
        proposerUrl: 'https://tokeninfo.aktionariat.com',
      ),
    );
  }

  @override
  Future<void> approveSession(String proposalId, {required String address}) async {}

  @override
  Future<void> rejectSession(String proposalId) async {}

  @override
  Future<void> approveRequest(int requestId, String result) async {}

  @override
  Future<void> rejectRequest(int requestId) async {}

  @override
  Future<void> disconnect(String topic) async {}
}

/// Advances until [WalletConnectSessionView] is on stage. Do not use
/// `pumpAndSettle` — the session page shows a [CupertinoActivityIndicator]
/// until the pairing prompt arrives, and that ticker never settles.
Future<void> _pumpUntilSessionView(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    if (find.byType(WalletConnectSessionView).evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Finishes a [MaterialPageRoute] pop (300ms) without waiting on infinite
/// tickers still in the outgoing route.
Future<void> _pumpPopComplete(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUpAll(() {
    stubMobileScannerChannel();
    GetIt.instance.registerSingleton<WalletConnectService>(
      WalletConnectService.forTesting(
        engine: _FakeEngine(),
        address: '0x1111111111111111111111111111111111111111',
        signMessage: (message) async => 'sig',
      ),
    );
  });

  tearDownAll(() async => GetIt.instance.reset());

  testWidgets(
    'two identical captures push WalletConnectSessionView once; re-arms after pop',
    (tester) async {
      await tester.pumpApp(const WalletConnectScanPage());

      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
      const capture = BarcodeCapture(barcodes: [Barcode(rawValue: _pairing)]);
      scanner.onDetect!(capture);
      scanner.onDetect!(capture); // second frame — must not push again
      await _pumpUntilSessionView(tester);

      expect(find.byType(WalletConnectSessionView), findsOne);

      Navigator.of(tester.element(find.byType(WalletConnectSessionView))).pop();
      await _pumpPopComplete(tester);
      expect(find.byType(WalletConnectSessionView), findsNothing);

      final scannerAfterPop = tester.widget<MobileScanner>(find.byType(MobileScanner));
      scannerAfterPop.onDetect!(capture);
      await _pumpUntilSessionView(tester);
      expect(find.byType(WalletConnectSessionView), findsOne);
    },
  );

  testWidgets(
    'a capture during the pop animation does not push a second session page',
    (tester) async {
      await tester.pumpApp(const WalletConnectScanPage());

      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
      final onDetect = scanner.onDetect!;
      const capture = BarcodeCapture(barcodes: [Barcode(rawValue: _pairing)]);
      onDetect(capture);
      await _pumpUntilSessionView(tester);
      expect(find.byType(WalletConnectSessionView), findsOne);

      Navigator.of(tester.element(find.byType(WalletConnectSessionView))).pop();
      await tester.pump(); // pop animation in flight — not settled
      onDetect(capture);
      await tester.pump();
      expect(find.byType(WalletConnectSessionView), findsOne);

      await _pumpPopComplete(tester);
      expect(find.byType(WalletConnectSessionView), findsNothing);
    },
  );
}
