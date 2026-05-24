import 'dart:async';
import 'dart:typed_data';

import 'package:bitbox_flutter/bitbox_flutter.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_credentials.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';

class _MockBitboxManager extends Mock implements BitboxManager {}

class _FakeBitboxDevice extends Fake implements BitboxDevice {}

class _ParseError implements Exception {}

void main() {
  late _MockBitboxManager manager;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    // The sign queue is a process-wide static; reset it so a hung-sign test
    // cannot leak a pending (or wrong-zone) queue head into the next test.
    BitboxCredentials.resetSignQueue();
    manager = _MockBitboxManager();
    // _runOrThrowDisconnect probes manager.devices to distinguish a real
    // disconnect from a sign-internal failure. Tests below that expect the
    // *original* error to surface must report the device as still connected.
    when(() => manager.devices).thenAnswer((_) async => <BitboxDevice>[
          _FakeBitboxDevice(),
        ]);
  });

  BitboxCredentials connected() =>
      BitboxCredentials('0x000000000000000000000000000000000000dead')..setBitbox(manager);

  group('$BitboxCredentials', () {
    test('isConnected is false until setBitbox is called', () {
      final c = BitboxCredentials('0x000000000000000000000000000000000000dead');
      expect(c.isConnected, isFalse);
    });

    test('setBitbox and clearBitbox toggle isConnected', () {
      final c = BitboxCredentials('0x000000000000000000000000000000000000dead');
      c.setBitbox(manager);
      expect(c.isConnected, isTrue);
      c.clearBitbox();
      expect(c.isConnected, isFalse);
    });

    test('signToSignature throws BitboxNotConnectedException when bitboxManager is null', () {
      final c = BitboxCredentials('0x000000000000000000000000000000000000dead');
      expect(
        () => c.signToSignature(Uint8List.fromList(List.filled(32, 0))),
        throwsA(isA<BitboxNotConnectedException>()),
      );
    });

    test('signToSignature strips the EIP-1559 type-prefix byte before sending', () async {
      final fakeSig = Uint8List.fromList(
        List<int>.filled(32, 0xAA) + List<int>.filled(32, 0xBB) + [0x01],
      );
      when(
        () => manager.signETHRLPTransaction(any(), any(), any(), any()),
      ).thenAnswer((_) async => fakeSig);

      final payload = Uint8List.fromList([0x02, 0xCA, 0xFE, 0xBA, 0xBE]);
      final sig = await connected().signToSignature(payload, chainId: 1, isEIP1559: true);

      expect(sig.v, 1, reason: 'EIP-1559 keeps the raw parity v as-is');
      final captured = verify(
        () => manager.signETHRLPTransaction(
          captureAny(),
          captureAny(),
          captureAny(),
          captureAny(),
        ),
      ).captured;
      expect(captured[2], 'cafebabe', reason: 'leading 0x02 must be stripped before hex-encoding');
    });

    test('signToSignature returns raw v for legacy (non-EIP-155) signatures', () async {
      // chainId=null, BitBox returns v in {27, 28}.
      final fakeSig = Uint8List.fromList(
        List<int>.filled(32, 0x11) + List<int>.filled(32, 0x22) + [27],
      );
      when(
        () => manager.signETHRLPTransaction(any(), any(), any(), any()),
      ).thenAnswer((_) async => fakeSig);

      final sig = await connected().signToSignature(Uint8List.fromList([0xDE, 0xAD]));
      expect(sig.v, 27);
    });

    test('signToSignature derives chainIdV for parity 0 (EIP-155)', () async {
      // chainId=1, EIP-155 v = chainId*2 + 35 = 37 (parity 0).
      final fakeSig = Uint8List.fromList(
        List<int>.filled(32, 0x11) + List<int>.filled(32, 0x22) + [37],
      );
      when(
        () => manager.signETHRLPTransaction(any(), any(), any(), any()),
      ).thenAnswer((_) async => fakeSig);

      final sig = await connected().signToSignature(Uint8List.fromList([0xDE, 0xAD]), chainId: 1);
      expect(sig.v, 37);
    });

    test('signToSignature derives chainIdV for parity 1 (EIP-155)', () async {
      final fakeSig = Uint8List.fromList(
        List<int>.filled(32, 0x11) + List<int>.filled(32, 0x22) + [38],
      );
      when(
        () => manager.signETHRLPTransaction(any(), any(), any(), any()),
      ).thenAnswer((_) async => fakeSig);

      final sig = await connected().signToSignature(Uint8List.fromList([0xDE, 0xAD]), chainId: 1);
      expect(sig.v, 38);
    });

    test('signPersonalMessage throws BitboxNotConnectedException when not connected', () {
      final c = BitboxCredentials('0x000000000000000000000000000000000000dead');
      expect(
        () => c.signPersonalMessage(Uint8List.fromList([1, 2, 3])),
        throwsA(isA<BitboxNotConnectedException>()),
      );
    });

    test('signPersonalMessage passes chainId and derivation path to the manager', () async {
      when(
        () => manager.signETHMessage(any(), any(), any()),
      ).thenAnswer((_) async => Uint8List.fromList(List.filled(65, 0x01)));

      final sig = await connected().signPersonalMessage(Uint8List.fromList([1, 2, 3]), chainId: 1);

      expect(sig.length, 65);
      final captured = verify(
        () => manager.signETHMessage(
          captureAny(),
          captureAny(),
          captureAny(),
        ),
      ).captured;
      expect(captured[0], 1);
      expect(captured[1], "m/44'/60'/0'/0/0");
    });

    test('signTypedDataV4 throws BitboxNotConnectedException when not connected', () {
      final c = BitboxCredentials('0x000000000000000000000000000000000000dead');
      expect(
        () => c.signTypedDataV4(1, '{"primaryType":"Foo"}'),
        throwsA(isA<BitboxNotConnectedException>()),
      );
    });

    test('signTypedDataV4 hex-encodes signature bytes with 0x prefix', () async {
      when(
        () => manager.signETHTypedMessage(any(), any(), any()),
      ).thenAnswer((_) async => Uint8List.fromList([0xCA, 0xFE, 0xBA, 0xBE]));

      final sig = await connected().signTypedDataV4(1, '{"primaryType":"Foo"}');
      expect(sig, '0xcafebabe');
    });

    test('serializes parallel signs through the static queue', () async {
      var inFlight = 0;
      var maxParallel = 0;
      when(() => manager.signETHTypedMessage(any(), any(), any())).thenAnswer((_) async {
        inFlight++;
        if (inFlight > maxParallel) maxParallel = inFlight;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        inFlight--;
        return Uint8List.fromList([0x01]);
      });

      final c = connected();
      await Future.wait([
        c.signTypedDataV4(1, '{"primaryType":"A"}'),
        c.signTypedDataV4(1, '{"primaryType":"B"}'),
        c.signTypedDataV4(1, '{"primaryType":"C"}'),
      ]);

      expect(maxParallel, 1);
    });

    test('queue continues after a sign throws (slot released in finally)', () async {
      // `_runOrThrowDisconnect` probes `manager.devices` on a thrown sign to
      // decide whether to relabel the error as BitboxNotConnectedException.
      // Stub it to a non-empty list so the original "first sign explodes"
      // survives — this test exercises the queue, not the disconnect path.
      when(() => manager.devices).thenAnswer((_) async => [_FakeBitboxDevice()]);

      var call = 0;
      when(() => manager.signETHTypedMessage(any(), any(), any())).thenAnswer((_) async {
        call++;
        if (call == 1) throw Exception('first sign explodes');
        return Uint8List.fromList([0x42]);
      });

      final c = connected();
      await expectLater(
        c.signTypedDataV4(1, '{"primaryType":"A"}'),
        throwsException,
      );
      final sig = await c
          .signTypedDataV4(1, '{"primaryType":"B"}')
          .timeout(const Duration(seconds: 1));
      expect(sig, '0x42');
    });

    // Post-#461 mid-flow recovery: _runOrThrowDisconnect must convert a
    // mid-sign plugin error into BitboxNotConnectedException only when the
    // device probe confirms the device is gone.
    test(
      'signToSignature surfaces BitboxNotConnectedException when device is gone mid-sign',
      () async {
        when(
          () => manager.signETHRLPTransaction(any(), any(), any(), any()),
        ).thenThrow(Exception('plugin: USB write failed mid-sign'));
        when(() => manager.devices).thenAnswer((_) async => <BitboxDevice>[]);

        final c = connected();
        await expectLater(
          c.signToSignature(Uint8List.fromList([0xDE, 0xAD]), chainId: 1),
          throwsA(isA<BitboxNotConnectedException>()),
        );
        expect(c.isConnected, isFalse, reason: 'clearBitbox must have run on lost device');
      },
    );

    // Post-#461 mid-flow recovery: a still-reachable device means the
    // original error wins; we must not mask real plugin/parse failures.
    test(
      'signToSignature rethrows the original error when device is still present mid-sign',
      () async {
        when(
          () => manager.signETHRLPTransaction(any(), any(), any(), any()),
        ).thenThrow(_ParseError());
        when(() => manager.devices).thenAnswer((_) async => [_FakeBitboxDevice()]);

        final c = connected();
        await expectLater(
          c.signToSignature(Uint8List.fromList([0xDE, 0xAD]), chainId: 1),
          throwsA(isA<_ParseError>()),
        );
        expect(c.isConnected, isTrue, reason: 'clearBitbox must NOT run when device is still there');
      },
    );

    // Post-#461 mid-flow recovery: if the probe itself blows up, _deviceLost
    // returns true (defensive fallback) and the disconnect path wins.
    test(
      'signToSignature treats device as lost when the device probe itself throws',
      () async {
        when(
          () => manager.signETHRLPTransaction(any(), any(), any(), any()),
        ).thenThrow(Exception('plugin: USB write failed mid-sign'));
        when(() => manager.devices).thenThrow(Exception('USB descriptor closed'));

        final c = connected();
        await expectLater(
          c.signToSignature(Uint8List.fromList([0xDE, 0xAD]), chainId: 1),
          throwsA(isA<BitboxNotConnectedException>()),
        );
        expect(c.isConnected, isFalse, reason: 'failed probe must be treated as lost device');
      },
    );

    // Cross-method guard: every sign method must route through
    // _runOrThrowDisconnect. Drive the disconnect path through
    // signTypedDataV4 so a future refactor that drops the wrap from one
    // method gets caught here.
    test(
      'signTypedDataV4 also routes through _runOrThrowDisconnect on device loss',
      () async {
        when(
          () => manager.signETHTypedMessage(any(), any(), any()),
        ).thenThrow(Exception('plugin: BLE drop mid-sign'));
        when(() => manager.devices).thenAnswer((_) async => <BitboxDevice>[]);

        final c = connected();
        await expectLater(
          c.signTypedDataV4(1, '{"primaryType":"Foo"}'),
          throwsA(isA<BitboxNotConnectedException>()),
        );
        expect(c.isConnected, isFalse, reason: 'clearBitbox must have run on lost device');
      },
    );

    // A hung native sign must not poison the static queue forever. After
    // `signQueueTimeout` the queue slot frees and the hung sign surfaces as
    // BitboxNotConnectedException to its caller.
    test('a never-completing sign resolves within signQueueTimeout', () {
      fakeAsync((async) {
        // Seed the queue head inside this zone (see resetSignQueue doc).
        BitboxCredentials.resetSignQueue();
        async.flushMicrotasks();

        // Native sign that never returns — simulates an Android USB hang.
        when(() => manager.signETHTypedMessage(any(), any(), any()))
            .thenAnswer((_) => Completer<Uint8List>().future);

        final c = connected();
        Object? thrown;
        c.signTypedDataV4(1, '{"primaryType":"A"}').catchError((Object e) {
          thrown = e;
          return '';
        });

        // Just before the bound: still pending.
        async.elapse(BitboxCredentials.signQueueTimeout - const Duration(seconds: 1));
        expect(thrown, isNull);

        // Past the bound: the hung sign surfaces as a typed exception.
        async.elapse(const Duration(seconds: 2));
        expect(thrown, isA<BitboxNotConnectedException>());
      });
    });

    // The whole point of the bug fix: one hung sign must not deadlock every
    // later sign chained off the static queue.
    test('a sign issued after a hung sign is not deadlocked', () {
      fakeAsync((async) {
        BitboxCredentials.resetSignQueue();
        async.flushMicrotasks();

        var call = 0;
        when(() => manager.signETHTypedMessage(any(), any(), any())).thenAnswer((_) async {
          call++;
          if (call == 1) return Completer<Uint8List>().future; // first sign hangs
          return Uint8List.fromList([0x42]);
        });

        final c = connected();
        Object? firstThrown;
        c.signTypedDataV4(1, '{"primaryType":"A"}').catchError((Object e) {
          firstThrown = e;
          return '';
        });

        String? secondResult;
        Object? secondThrown;
        c.signTypedDataV4(1, '{"primaryType":"B"}').then((v) {
          secondResult = v;
        }).catchError((Object e) {
          secondThrown = e;
        });

        // Drain past the queue guard so the hung slot frees.
        async.elapse(BitboxCredentials.signQueueTimeout + const Duration(seconds: 1));
        async.flushMicrotasks();

        expect(firstThrown, isA<BitboxNotConnectedException>());
        // The second sign must NOT hang — but since the device was cleared by
        // the timed-out first sign, it fails fast rather than racing the
        // device.
        expect(secondResult, isNull);
        expect(secondThrown, isA<BitboxNotConnectedException>());
      });
    });

    // Requirement 3: a timed-out sign clears the device so a subsequent sign
    // cannot talk to a device whose native op may still be in flight — it hits
    // the `manager == null` guard and fails fast without touching the device.
    test('device is cleared after a hung sign so the next sign fails fast', () {
      fakeAsync((async) {
        BitboxCredentials.resetSignQueue();
        async.flushMicrotasks();

        // First sign hangs forever; later signs would otherwise hit the mock.
        when(() => manager.signETHTypedMessage(any(), any(), any()))
            .thenAnswer((_) => Completer<Uint8List>().future);

        final c = connected();
        expect(c.isConnected, isTrue);

        c.signTypedDataV4(1, '{"primaryType":"A"}').catchError((Object _) => '');
        async.elapse(BitboxCredentials.signQueueTimeout + const Duration(seconds: 1));
        async.flushMicrotasks();

        expect(c.isConnected, isFalse, reason: 'clearBitbox must run on a timed-out sign');

        // The next sign hits the manager == null guard: it fails fast with a
        // typed exception and never invokes the device sign mock again.
        Object? nextThrown;
        c.signTypedDataV4(1, '{"primaryType":"B"}').catchError((Object e) {
          nextThrown = e;
          return '';
        });
        async.flushMicrotasks();

        expect(nextThrown, isA<BitboxNotConnectedException>());
        verify(() => manager.signETHTypedMessage(any(), any(), any())).called(1);
      });
    });

    // Requirement 5: the normal path must stay serialised and in order.
    test('normal serialised signing completes in order', () async {
      final order = <String>[];
      when(() => manager.signETHTypedMessage(any(), any(), any())).thenAnswer((invocation) async {
        final data = invocation.positionalArguments[2] as Uint8List;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        order.add(String.fromCharCodes(data));
        return Uint8List.fromList([0x01]);
      });

      final c = connected();
      await Future.wait([
        c.signTypedDataV4(1, 'A'),
        c.signTypedDataV4(1, 'B'),
        c.signTypedDataV4(1, 'C'),
      ]);

      expect(order, ['A', 'B', 'C']);
    });

    test('sign on cleared credentials throws BitboxNotConnectedException, not NoSuchMethod',
        () async {
      // Snapshot semantics (3.2) — the manager may be nulled by the observer
      // between the connection check and the sign call. The snapshot-on-entry
      // pattern means the null check fires and the bang-operator path is
      // never reached.
      final c = BitboxCredentials('0x000000000000000000000000000000000000dead')
        ..setBitbox(manager);
      c.clearBitbox();

      await expectLater(
        c.signTypedDataV4(1, '{"primaryType":"A"}'),
        throwsA(isA<BitboxNotConnectedException>()),
      );
    });

    // -----------------------------------------------------------------------
    // Initiative I (ADR 0001) — sign-queue timeout propagation.
    //
    // Pre-Initiative-I, a timed-out sign cleared credentials but left
    // BitboxService thinking we were still Paired. The consuming cubit had to
    // poll currentStatus to discover the loss. The fix wires an
    // `_onSignQueueTimeout` closure that the service installs via
    // `getCredentials`, and the timeout branch calls it before throwing
    // BitboxNotConnectedException.
    //
    // The tests below pin BOTH effects (clearBitbox AND the closure call) so
    // a future refactor that drops one half flips the assertion immediately.
    // -----------------------------------------------------------------------

    test(
      'a hung sign fires the _onSignQueueTimeout callback once AND clears credentials',
      () {
        fakeAsync((async) {
          BitboxCredentials.resetSignQueue();
          async.flushMicrotasks();

          when(() => manager.signETHTypedMessage(any(), any(), any()))
              .thenAnswer((_) => Completer<Uint8List>().future);

          var timeoutCalls = 0;
          final c = BitboxCredentials(
            '0x000000000000000000000000000000000000dead',
            () => timeoutCalls++,
          )..setBitbox(manager);

          c.signTypedDataV4(1, '{"primaryType":"A"}').catchError(
            (Object _) => '',
          );

          // Before the bound the callback has NOT fired.
          async.elapse(
            BitboxCredentials.signQueueTimeout - const Duration(seconds: 1),
          );
          async.flushMicrotasks();
          expect(timeoutCalls, 0, reason: 'callback must not fire pre-timeout');

          // Past the bound the callback fires exactly once, and credentials
          // are cleared.
          async.elapse(const Duration(seconds: 2));
          async.flushMicrotasks();
          expect(timeoutCalls, 1,
              reason: 'sign-queue timeout must invoke the closure exactly once');
          expect(c.isConnected, isFalse,
              reason: 'sign-queue timeout must clear local credentials');
        });
      },
    );

    test(
      'a successful sign does NOT invoke the _onSignQueueTimeout callback',
      () async {
        // Negative pin: the callback is strictly a timeout signal; a normal
        // sign-success path must not flip the service to Lost.
        var timeoutCalls = 0;
        when(() => manager.signETHTypedMessage(any(), any(), any()))
            .thenAnswer((_) async => Uint8List.fromList([0x42]));

        final c = BitboxCredentials(
          '0x000000000000000000000000000000000000dead',
          () => timeoutCalls++,
        )..setBitbox(manager);

        await c.signTypedDataV4(1, '{"primaryType":"OK"}');
        expect(timeoutCalls, 0);
        expect(c.isConnected, isTrue,
            reason: 'a successful sign keeps the credentials attached');
      },
    );

    test(
      'a sign that throws (non-timeout) does NOT invoke _onSignQueueTimeout',
      () async {
        // Distinguish the timeout path from generic native-error paths.
        // A native sign-error must surface as its own exception; only the
        // queue-timeout flips the service-level state to Lost.
        var timeoutCalls = 0;
        when(() => manager.signETHTypedMessage(any(), any(), any()))
            .thenThrow(_ParseError());

        final c = BitboxCredentials(
          '0x000000000000000000000000000000000000dead',
          () => timeoutCalls++,
        )..setBitbox(manager);

        await expectLater(
          c.signTypedDataV4(1, '{"primaryType":"A"}'),
          throwsA(isA<_ParseError>()),
        );
        expect(timeoutCalls, 0,
            reason: 'native-error path must not trigger the service-Lost flow');
      },
    );

    test(
      'omitting the callback keeps the timeout path safe (no NPE)',
      () {
        // Defensive guard: the callback parameter is optional. A test or
        // construction-site that never wires the closure must still see the
        // timeout path complete — the closure call is null-aware.
        fakeAsync((async) {
          BitboxCredentials.resetSignQueue();
          async.flushMicrotasks();

          when(() => manager.signETHTypedMessage(any(), any(), any()))
              .thenAnswer((_) => Completer<Uint8List>().future);

          final c = BitboxCredentials(
            '0x000000000000000000000000000000000000dead',
          )..setBitbox(manager);

          Object? thrown;
          c.signTypedDataV4(1, '{"primaryType":"A"}').catchError(
            (Object e) {
              thrown = e;
              return '';
            },
          );
          async.elapse(
            BitboxCredentials.signQueueTimeout + const Duration(seconds: 1),
          );
          async.flushMicrotasks();

          expect(thrown, isA<BitboxNotConnectedException>(),
              reason: 'no callback wired still surfaces the typed exception');
        });
      },
    );

    test(
      'property: across a sequence with mid-timeout, callback fires exactly once before any subsequent sign',
      () {
        // Property pin (hand-rolled loop): for every mid-sign timeout in a
        // sequence of K signs, the callback must fire exactly once and the
        // remaining signs must observe `isConnected == false` (post-timeout)
        // BEFORE they reach the device. Iterates over K in [1..6] so an
        // off-by-one in the queue-slot release surfaces.
        for (var totalSigns = 1; totalSigns <= 6; totalSigns++) {
          fakeAsync((async) {
            BitboxCredentials.resetSignQueue();
            async.flushMicrotasks();

            var nativeCalls = 0;
            when(() => manager.signETHTypedMessage(any(), any(), any()))
                .thenAnswer((_) {
              nativeCalls++;
              // Every native call hangs; the queue-timeout must clean up.
              return Completer<Uint8List>().future;
            });

            var timeoutCalls = 0;
            final c = BitboxCredentials(
              '0x000000000000000000000000000000000000dead',
              () => timeoutCalls++,
            )..setBitbox(manager);

            // Issue K signs. After the first one hits the timeout, every
            // subsequent sign must fail fast (manager == null guard) without
            // ever reaching the native mock.
            final thrown = <Object?>[];
            for (var i = 0; i < totalSigns; i++) {
              c.signTypedDataV4(1, '{"primaryType":"P$i"}').catchError(
                (Object e) {
                  thrown.add(e);
                  return '';
                },
              );
            }

            async.elapse(
              BitboxCredentials.signQueueTimeout +
                  const Duration(seconds: 2),
            );
            async.flushMicrotasks();

            expect(timeoutCalls, 1,
                reason: 'totalSigns=$totalSigns: callback must fire exactly once');
            expect(c.isConnected, isFalse);
            // Native mock must have been called exactly once — the first
            // sign — and never again because subsequent signs see the
            // detached manager and fail fast at the snapshot null-check.
            expect(nativeCalls, 1,
                reason:
                    'totalSigns=$totalSigns: post-timeout signs must NOT reach the device');
            // Every sign in the batch must observe the typed exception.
            for (final t in thrown) {
              expect(t, isA<BitboxNotConnectedException>());
            }
            expect(thrown.length, totalSigns,
                reason: 'all signs must terminate with a typed exception');
          });
        }
      },
    );
  });
}
