import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/walletconnect/walletconnect_engine.dart';
import 'package:realunit_wallet/packages/walletconnect/walletconnect_service.dart';
import 'package:realunit_wallet/screens/walletconnect/walletconnect_session_page.dart';

import '../../helper/helper.dart';

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

  group('WalletConnectSessionView responsive matrix', () {
    for (final cell in kFullResponsiveMatrix) {
      testWidgets(cell.id, (tester) async {
        await withTargetPlatform(cell.device.platform, () async {
          await expectNoLayoutOverflow(
            tester,
            () async {
              await tester.binding.setSurfaceSize(cell.mediaQuery.size);
              addTearDown(() async => await tester.binding.setSurfaceSize(null));
              await tester.pumpApp(
                MediaQuery(
                  data: cell.mediaQuery,
                  child: const WalletConnectSessionView(
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
              await tester.pump();
            },
            reason: 'WalletConnectSessionView overflow / ${cell.label}',
          );

          await expectFullyTappable(
            tester,
            find.widgetWithText(FilledButton, S.current.walletConnectApprove),
            within: find.byType(WalletConnectSessionView),
            reason: 'WalletConnectSessionView / ${cell.label}: Connect CTA not tappable',
          );
        });
      });
    }
  });
}
