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
      scanner.onDetect!(capture);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(WalletConnectSessionView), findsOne);

      Navigator.of(tester.element(find.byType(WalletConnectSessionView))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(WalletConnectSessionView), findsNothing);

      final scannerAfterPop = tester.widget<MobileScanner>(find.byType(MobileScanner));
      scannerAfterPop.onDetect!(capture);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(WalletConnectSessionView), findsOne);
    },
  );
}
