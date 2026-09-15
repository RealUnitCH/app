import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:realunit_wallet/packages/walletconnect/walletconnect_engine.dart';
import 'package:realunit_wallet/packages/walletconnect/walletconnect_service.dart';
import 'package:realunit_wallet/screens/walletconnect/walletconnect_session_page.dart';

import '../../../helper/helper.dart';

class _FakeEngine implements WalletConnectEngine {
  final _events = StreamController<WalletConnectIncoming>.broadcast();

  @override
  Stream<WalletConnectIncoming> get events => _events.stream;

  @override
  Future<void> init({required String address, required List<int> chainIds}) async {}

  @override
  Future<void> pair(String uri) async {}

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

  @override
  Future<void> reset() async {}
}

void main() {
  setUpAll(() {
    GetIt.instance.registerSingleton<WalletConnectService>(
      WalletConnectService.forTesting(
        engine: _FakeEngine(),
        address: '0x1111111111111111111111111111111111111111',
        signMessage: (message) async => 'sig',
      ),
    );
  });

  tearDownAll(() async => GetIt.instance.reset());

  group('$WalletConnectSessionView', () {
    goldenTest(
      'waiting for proposal',
      fileName: 'walletconnect_session_page_loading',
      constraints: phoneConstraints,
      // The CupertinoActivityIndicator animates forever, so pumpAndSettle
      // would time out; pumpOnce captures the first frame.
      pumpBeforeTest: pumpOnce,
      builder: () => wrapForGolden(
        const WalletConnectSessionView(),
      ),
    );

    goldenTest(
      'proposal from Aktionariat',
      fileName: 'walletconnect_session_page_proposal',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        const WalletConnectSessionView(
          initialPrompt: WalletConnectProposalPrompt(
            WalletConnectSessionProposal(
              proposalId: '1',
              originUrl: 'https://tokeninfo.aktionariat.com',
              verifyStatus: WalletConnectVerifyStatus.valid,
              proposerName: 'Aktionariat',
              proposerUrl: 'https://tokeninfo.aktionariat.com',
            ),
          ),
        ),
      ),
    );

    goldenTest(
      'personal_sign request',
      fileName: 'walletconnect_session_page_sign',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        const WalletConnectSessionView(
          initialPrompt: WalletConnectRequestPrompt(
            request: WalletConnectSessionRequest(
              requestId: 1,
              topic: 'topic-1',
              method: 'personal_sign',
              params: [
                '0x68656c6c6f',
                '0x1111111111111111111111111111111111111111',
              ],
              originUrl: 'https://tokeninfo.aktionariat.com',
              verifyStatus: WalletConnectVerifyStatus.valid,
              chainId: 1,
            ),
            messagePreview: 'hello',
          ),
        ),
      ),
    );
  });
}
