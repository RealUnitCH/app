import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:realunit_wallet/packages/walletconnect/walletconnect_engine.dart';
import 'package:realunit_wallet/packages/walletconnect/walletconnect_service.dart';
import 'package:realunit_wallet/screens/walletconnect/walletconnect_session_page.dart';

import '../../helper/helper.dart';

const _pairing =
    'wc:00e46b69-d0cc-4b3e-b6a2-cee442f97188@2?relay-protocol=irn&symKey=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

const _prompt = WalletConnectRequestPrompt(
  request: WalletConnectSessionRequest(
    requestId: 1,
    topic: 'topic-1',
    method: 'personal_sign',
    params: ['0x68656c6c6f', '0x1111111111111111111111111111111111111111'],
    originUrl: 'https://app.frankencoin.com',
    verifyStatus: WalletConnectVerifyStatus.valid,
  ),
  messagePreview: 'hello',
);

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

/// Do not use `pumpAndSettle` — the session page shows a
/// [CupertinoActivityIndicator] while `_prompt == null`, and that ticker
/// never settles.
Future<void> _pumpUntilSessionPageGone(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    if (find.byType(WalletConnectSessionPage).evaluate().isEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late _FakeEngine engine;

  setUp(() async {
    engine = _FakeEngine();
    final service = WalletConnectService.forTesting(
      engine: engine,
      address: '0x1111111111111111111111111111111111111111',
      signMessage: (_) async => '0x',
    );
    GetIt.instance.registerSingleton<WalletConnectService>(service);
    await service.pair(_pairing);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('device cancel on Sign pops the session page', (tester) async {
    await tester.pumpApp(
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const WalletConnectSessionPage(initialPrompt: _prompt),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump(); // push
    await tester.pump(); // build session page
    expect(find.byType(WalletConnectSessionPage), findsOne);
    await tester.ensureVisible(find.text('Sign'));
    await tester.tap(find.text('Sign'));
    await tester.pump();
    await _pumpUntilSessionPageGone(tester);

    expect(find.byType(WalletConnectSessionPage), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });
}
