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

class _FakeEngine implements WalletConnectEngine {
  final _events = StreamController<WalletConnectIncoming>.broadcast();
  Object? pairError;

  @override
  Stream<WalletConnectIncoming> get events => _events.stream;

  @override
  Future<void> init({required String address, required List<int> chainIds}) async {}

  @override
  Future<void> pair(String uri) async {
    final error = pairError;
    if (error != null) throw error;
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

Future<void> _openSession(WidgetTester tester, {required String pairingUri}) async {
  await tester.pumpApp(
    Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => WalletConnectSessionPage(pairingUri: pairingUri),
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
  await tester.pump(); // post-frame _pair
}

/// Pair is async (`ensureInitialized` then `engine.pair`). Do not use
/// `pumpAndSettle` — the session page shows a [CupertinoActivityIndicator]
/// until the prompt arrives, and that ticker never settles.
Future<void> _pumpUntilSnackBar(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    if (find.byType(SnackBar).evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late _FakeEngine engine;

  setUp(() {
    engine = _FakeEngine();
    GetIt.instance.registerSingleton<WalletConnectService>(
      WalletConnectService.forTesting(
        engine: engine,
        address: '0x1111111111111111111111111111111111111111',
        signMessage: (message) async => 'sig',
      ),
    );
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('invalid pairing URI shows SnackBar and pops', (tester) async {
    await _openSession(tester, pairingUri: 'not-a-wc-uri');
    await _pumpUntilSnackBar(tester);

    expect(find.byType(SnackBar), findsOne);
    expect(find.text('This is not a valid WalletConnect URI.'), findsOne);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(WalletConnectSessionPage), findsNothing);
  });

  testWidgets('engine pair error shows SnackBar and pops', (tester) async {
    engine.pairError = StateError('relay down');
    await _openSession(tester, pairingUri: _pairing);
    await _pumpUntilSnackBar(tester);

    expect(find.byType(SnackBar), findsOne);
    expect(find.text('This is not a valid WalletConnect URI.'), findsOne);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(WalletConnectSessionPage), findsNothing);
  });
}
