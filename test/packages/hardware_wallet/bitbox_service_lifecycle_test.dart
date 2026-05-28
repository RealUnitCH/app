import 'dart:async';
import 'dart:typed_data';

import 'package:bitbox_flutter/bitbox_flutter.dart';
import 'package:bitbox_flutter/testing.dart';
import 'package:bitbox_flutter/usb/bitbox_usb_platform_interface.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_credentials.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_connection_status.dart';

// Lifecycle conformance suite — pins the Initiative I contract: a single
// Stream<BitboxConnectionStatus> owned by BitboxService is the only truth
// for connect-state, and the state-machine traversal is exactly the one
// declared in ADR 0001.
//
// Property-style coverage:
//   - For any sequence of init/clear/signalDeviceLost, observed Stream is a
//     valid traversal (no Disconnected→InUse without Paired, etc.).
//   - For any concurrent init() calls, exactly one bitboxManager.connect()
//     is invoked.
//   - dispose() rejects subsequent init() with StateError; no Stream
//     emissions after dispose().
//
// All time-sensitive cases drive the periodic observer inside fakeAsync so
// virtual time replaces wall-clock Future.delayed — keeps the suite under
// 200ms total even though the observer interval is artificially fast (50ms).
void main() {
  late BitboxUsbPlatform previousPlatform;
  late SimulatedBitboxPlatform platform;

  const fastInterval = Duration(milliseconds: 50);
  const observerSettleTime = Duration(milliseconds: 150);

  setUp(() {
    previousPlatform = BitboxUsbPlatform.instance;
    platform = installSimulatedBitboxPlatform();
  });

  tearDown(() {
    BitboxUsbPlatform.instance = previousPlatform;
  });

  /// Pair the service inside an existing fakeAsync zone. Returns the device
  /// the service is now paired to. Must NOT be called outside fakeAsync.
  BitboxDevice pairServiceSync(FakeAsync async, BitboxService service) {
    late List<BitboxDevice> devices;
    service.getAllUsbDevices().then((d) => devices = d);
    async.flushMicrotasks();
    service.init(devices.single);
    async.flushMicrotasks();
    return devices.single;
  }

  /// Collect every status emission until the disposable subscription is
  /// cancelled by [addTearDown]. Sized to be appendable across fakeAsync
  /// boundaries.
  List<BitboxConnectionStatus> observe(BitboxService service) {
    final emitted = <BitboxConnectionStatus>[];
    final sub = service.status.listen(emitted.add);
    addTearDown(sub.cancel);
    return emitted;
  }

  group('Stream replay-last semantics', () {
    test('a fresh subscriber synchronously receives Disconnected as initial state', () {
      // Replay-last contract: subscribing late must NOT leave the consumer
      // blind to the current state until the next transition. Without this,
      // a cubit constructed after the service has paired would render
      // "BitboxNotConnected" until something happened to bump the stream.
      fakeAsync((async) {
        final service = BitboxService(connectionStatusInterval: fastInterval);
        addTearDown(service.dispose);

        final observed = observe(service);
        async.flushMicrotasks();

        expect(observed, isNotEmpty, reason: 'late subscriber must receive replayed status');
        expect(observed.first, equals(const Disconnected()));
      });
    });

    test('the latest status is replayed even after multiple transitions', () {
      fakeAsync((async) {
        final service = BitboxService(connectionStatusInterval: fastInterval);
        addTearDown(service.dispose);

        pairServiceSync(async, service);
        async.flushMicrotasks();

        // Subscribe AFTER the Paired transition.
        final observed = observe(service);
        async.flushMicrotasks();

        expect(
          observed.last,
          isA<Paired>(),
          reason: 'replay-last must surface the post-transition state',
        );
      });
    });

    test('currentStatus exposes the most recent emission without subscribing', () {
      fakeAsync((async) {
        final service = BitboxService(connectionStatusInterval: fastInterval);
        addTearDown(service.dispose);

        expect(
          service.currentStatus,
          equals(const Disconnected()),
          reason: 'pre-init currentStatus is Disconnected',
        );

        pairServiceSync(async, service);
        async.flushMicrotasks();

        expect(
          service.currentStatus,
          isA<Paired>(),
          reason: 'post-init currentStatus follows the stream',
        );
      });
    });
  });

  group('init() lifecycle', () {
    test('init() emits Connecting then Paired on success', () {
      fakeAsync((async) {
        final service = BitboxService(connectionStatusInterval: fastInterval);
        addTearDown(service.dispose);

        final observed = observe(service);
        pairServiceSync(async, service);
        async.flushMicrotasks();

        // Drop the replayed Disconnected so the trail describes only
        // the transitions caused by init().
        final transitions = observed.skipWhile((s) => s is Disconnected).toList(growable: false);
        expect(
          transitions.map((s) => s.runtimeType).toList(),
          containsAllInOrder(<Type>[Connecting, Paired]),
          reason: 'init() must walk Connecting → Paired',
        );
      });
    });

    test('init() emits Connecting then Disconnected when initBitBox returns false', () {
      // Failure path: the SDK returned `false`. The service must NOT promote
      // any credentials and must NOT linger in Connecting — it has to walk
      // back to Disconnected so the cubit can decide to retry.
      fakeAsync((async) {
        platform.when(SimulatedBitboxMethod.initBitBox, (_) async => false);

        final service = BitboxService(connectionStatusInterval: fastInterval);
        addTearDown(service.dispose);

        final observed = observe(service);
        late List<BitboxDevice> devices;
        service.getAllUsbDevices().then((d) => devices = d);
        async.flushMicrotasks();

        Object? caught;
        service.init(devices.single).catchError((Object e) {
          caught = e;
          return const Disconnected() as BitboxConnectionStatus;
        });
        async.flushMicrotasks();

        expect(caught, isA<Exception>(), reason: 'init() must throw when initBitBox returns false');

        final transitions = observed.skipWhile((s) => s is Disconnected).toList(growable: false);
        expect(
          transitions.map((s) => s.runtimeType).toList(),
          containsAllInOrder(<Type>[Connecting, Disconnected]),
        );
        expect(service.currentStatus, equals(const Disconnected()));
      });
    });

    test('init() emits Disconnected when the native init throws mid-Connecting', () {
      fakeAsync((async) {
        platform.throwOn(SimulatedBitboxMethod.initBitBox, Exception('native init boom'));

        final service = BitboxService(connectionStatusInterval: fastInterval);
        addTearDown(service.dispose);

        final observed = observe(service);
        late List<BitboxDevice> devices;
        service.getAllUsbDevices().then((d) => devices = d);
        async.flushMicrotasks();

        Object? caught;
        service.init(devices.single).catchError((Object e) {
          caught = e;
          return const Disconnected() as BitboxConnectionStatus;
        });
        async.flushMicrotasks();

        expect(caught, isA<Exception>());
        expect(
          observed.map((s) => s.runtimeType).toList(),
          containsAllInOrder(<Type>[Connecting, Disconnected]),
        );
        expect(service.currentStatus, equals(const Disconnected()));
      });
    });

    test('concurrent init() calls share a single bitboxManager.connect()', () {
      // Property: for any N concurrent init() invocations the underlying SDK
      // must see exactly one connect(). The shared-future guard is the only
      // defence against two BLE handshakes racing on the same noise channel.
      fakeAsync((async) {
        final service = BitboxService(connectionStatusInterval: fastInterval);
        addTearDown(service.dispose);

        late List<BitboxDevice> devices;
        service.getAllUsbDevices().then((d) => devices = d);
        async.flushMicrotasks();

        final results = <BitboxConnectionStatus>[];
        Object? firstError;
        Object? secondError;
        Object? thirdError;
        service.init(devices.single).then(results.add).catchError((Object e) {
          firstError = e;
        });
        service.init(devices.single).then(results.add).catchError((Object e) {
          secondError = e;
        });
        service.init(devices.single).then(results.add).catchError((Object e) {
          thirdError = e;
        });
        async.flushMicrotasks();

        expect(firstError, isNull);
        expect(secondError, isNull);
        expect(thirdError, isNull);
        expect(results.length, 3, reason: 'every caller receives the shared result');
        expect(
          platform.count(SimulatedBitboxMethod.initBitBox),
          1,
          reason: 'exactly one initBitBox per concurrent init() batch (property pin)',
        );
      });
    });

    test('init() after a successful pair is a no-op when re-driven by checkForBitbox', () {
      // Defensive pin: the service already exposes a connected manager. A
      // second init() with the same device must short-circuit (return the
      // current Paired status) without re-issuing connect/initBitBox.
      fakeAsync((async) {
        final service = BitboxService(connectionStatusInterval: fastInterval);
        addTearDown(service.dispose);
        final device = pairServiceSync(async, service);
        final initsAfterPair = platform.count(SimulatedBitboxMethod.initBitBox);

        BitboxConnectionStatus? result;
        service.init(device).then((s) => result = s);
        async.flushMicrotasks();

        expect(
          result,
          isA<Paired>(),
          reason: 'redundant init() resolves to the live Paired status',
        );
        expect(
          platform.count(SimulatedBitboxMethod.initBitBox),
          initsAfterPair,
          reason: 'redundant init() must not re-call initBitBox',
        );
      });
    });
  });

  group('clear() semantics', () {
    test('clear() emits Disconnecting → Disconnected and empties the credentials map', () {
      fakeAsync((async) {
        final service = BitboxService(connectionStatusInterval: fastInterval);
        addTearDown(service.dispose);
        pairServiceSync(async, service);

        // Hand out one credential so the cleanup path has something to
        // empty — pinned via isConnected before vs. after.
        final credentials = service.getCredentials('0x000000000000000000000000000000000000dead');
        expect(credentials.isConnected, isTrue);

        final observed = observe(service);
        service.clear();
        async.flushMicrotasks();

        final trail = observed.skipWhile((s) => s is! Paired).skip(1).toList(growable: false);
        expect(
          trail.map((s) => s.runtimeType).toList(),
          equals(<Type>[Disconnecting, Disconnected]),
          reason: 'clear() walks Paired → Disconnecting → Disconnected',
        );
        expect(
          credentials.isConnected,
          isFalse,
          reason: 'clear() must detach every credentials in the map',
        );
      });
    });

    test('clear() on Disconnected is a no-op (idempotent)', () {
      fakeAsync((async) {
        final service = BitboxService(connectionStatusInterval: fastInterval);
        addTearDown(service.dispose);

        final observed = observe(service);
        service.clear();
        async.flushMicrotasks();
        service.clear();
        async.flushMicrotasks();

        // Only the replayed initial Disconnected — no Disconnecting → Disconnected
        // round-trip should fire from a state where there's nothing to clear.
        expect(
          observed.whereType<Disconnecting>(),
          isEmpty,
          reason: 'clear() from Disconnected must not emit Disconnecting',
        );
      });
    });

    test('clear() drops the credentials map so a re-paired session starts fresh', () {
      fakeAsync((async) {
        final service = BitboxService(connectionStatusInterval: fastInterval);
        addTearDown(service.dispose);
        pairServiceSync(async, service);

        final beforeClear = service.getCredentials('0x000000000000000000000000000000000000dead');
        expect(beforeClear.isConnected, isTrue);

        service.clear();
        async.flushMicrotasks();

        // After clear() the map is empty — same address must hand out a
        // DIFFERENT BitboxCredentials instance, not the cleared one.
        final afterClear = service.getCredentials('0x000000000000000000000000000000000000dead');
        expect(
          identical(beforeClear, afterClear),
          isFalse,
          reason: 'clear() must drop the credentials map',
        );
        expect(
          afterClear.isConnected,
          isFalse,
          reason: 'fresh credentials handed out before re-init are detached',
        );
      });
    });
  });

  group('signalDeviceLost()', () {
    test('emits Lost(reason) with the supplied reason and tears down the observer', () {
      fakeAsync((async) {
        final service = BitboxService(connectionStatusInterval: fastInterval);
        addTearDown(service.dispose);
        pairServiceSync(async, service);
        final credentials = service.getCredentials('0x000000000000000000000000000000000000dead');
        expect(credentials.isConnected, isTrue);

        service.startConnectionStatusObserver();
        final observed = observe(service);

        service.signalDeviceLost(LostReason.signQueueTimeout);
        async.flushMicrotasks();

        expect(observed.last, equals(const Lost(LostReason.signQueueTimeout)));
        expect(
          credentials.isConnected,
          isFalse,
          reason: 'signalDeviceLost must detach every credentials',
        );

        // Observer ticks must stop firing after Lost — the next tick would
        // otherwise duplicate the lost transition with deviceUnreachable.
        final ticksBefore = platform.count(SimulatedBitboxMethod.getDevices);
        async.elapse(observerSettleTime * 2);
        expect(
          platform.count(SimulatedBitboxMethod.getDevices),
          ticksBefore,
          reason: 'observer must be cancelled by signalDeviceLost',
        );
      });
    });

    test('credentials sign-queue timeout emits Lost(signQueueTimeout)', () {
      fakeAsync((async) {
        final service = BitboxService(connectionStatusInterval: fastInterval);
        addTearDown(service.dispose);
        pairServiceSync(async, service);
        final observed = observe(service);
        final credentials = service.getCredentials('0x000000000000000000000000000000000000dead');

        platform.when(
          SimulatedBitboxMethod.signETHTypedMessage,
          (_) => Completer<Uint8List>().future,
        );

        credentials.signTypedDataV4(1, '{"primaryType":"A"}').catchError((Object _) => '');
        async.elapse(BitboxCredentials.signQueueTimeout + const Duration(seconds: 1));
        async.flushMicrotasks();

        expect(observed.whereType<Lost>().last, const Lost(LostReason.signQueueTimeout));
        expect(credentials.isConnected, isFalse);
      });
    });

    test('signalDeviceLost() from Disconnected is a no-op', () {
      // Defensive: a stale credentials reference firing signalDeviceLost
      // after the service has already cleared must NOT emit a Lost — the
      // consumer would see "lost while never connected" which violates the
      // state machine.
      fakeAsync((async) {
        final service = BitboxService(connectionStatusInterval: fastInterval);
        addTearDown(service.dispose);

        final observed = observe(service);
        service.signalDeviceLost(LostReason.signQueueTimeout);
        async.flushMicrotasks();

        expect(
          observed.whereType<Lost>(),
          isEmpty,
          reason: 'signalDeviceLost from Disconnected must be a no-op',
        );
      });
    });

    test('signalDeviceLost() carries every documented reason verbatim', () {
      // Exhaustive: every LostReason value must traverse through the
      // controller — proves the service doesn't silently drop unfamiliar
      // values via a switch-default arm.
      for (final reason in LostReason.values) {
        fakeAsync((async) {
          final service = BitboxService(connectionStatusInterval: fastInterval);
          addTearDown(service.dispose);
          pairServiceSync(async, service);

          final observed = observe(service);
          service.signalDeviceLost(reason);
          async.flushMicrotasks();

          expect(
            observed.last,
            equals(Lost(reason)),
            reason: 'reason $reason must reach the stream untranslated',
          );
        });
      }
    });

    test('signalDeviceLost() then clear() walks Lost → Disconnecting → Disconnected', () {
      fakeAsync((async) {
        final service = BitboxService(connectionStatusInterval: fastInterval);
        addTearDown(service.dispose);
        pairServiceSync(async, service);

        final observed = observe(service);
        service.signalDeviceLost(LostReason.signQueueTimeout);
        async.flushMicrotasks();
        service.clear();
        async.flushMicrotasks();

        final trail = observed.map((s) => s.runtimeType).toList();
        // Order: ... Paired Lost Disconnecting Disconnected
        expect(
          trail,
          containsAllInOrder(<Type>[
            Paired,
            Lost,
            Disconnecting,
            Disconnected,
          ]),
        );
      });
    });
  });

  group('observer-driven device loss', () {
    test('observer emits Lost(deviceUnreachable) when devices vanish', () {
      // The observer used to silently flip _isConnected and clear credentials
      // without surfacing the transition. Stream model promotes that into a
      // visible Lost(deviceUnreachable) so the cubit can route to the
      // reconnect sheet without polling currentStatus.
      fakeAsync((async) {
        final service = BitboxService(connectionStatusInterval: fastInterval);
        addTearDown(service.dispose);
        pairServiceSync(async, service);
        final credentials = service.getCredentials('0x000000000000000000000000000000000000dead');

        platform.when(
          SimulatedBitboxMethod.getDevices,
          (_) async => const <BitboxDevice>[],
        );
        final observed = observe(service);
        service.startConnectionStatusObserver();
        async.elapse(observerSettleTime);

        expect(
          observed.whereType<Lost>(),
          isNotEmpty,
          reason: 'observer must emit Lost on device vanish',
        );
        expect(
          observed.whereType<Lost>().last.reason,
          equals(LostReason.deviceUnreachable),
        );
        expect(credentials.isConnected, isFalse);
      });
    });
  });

  group('dispose()', () {
    test('dispose() emits a final Disconnected and closes the stream', () async {
      final service = BitboxService(connectionStatusInterval: fastInterval);

      final observed = <BitboxConnectionStatus>[];
      final done = Completer<void>();
      service.status.listen(observed.add, onDone: done.complete);

      await service.dispose();
      // The broadcast controller must close so onDone fires for the
      // subscriber, which is how cubits know to drop their subscription
      // on hot-restart.
      await done.future.timeout(const Duration(seconds: 1));
      expect(observed.last, equals(const Disconnected()));
    });

    test('init() after dispose() throws StateError', () async {
      final service = BitboxService(connectionStatusInterval: fastInterval);
      final devices = await service.getAllUsbDevices();
      await service.dispose();

      expect(
        () => service.init(devices.single),
        throwsA(isA<StateError>()),
      );
    });

    test('dispose() is idempotent', () async {
      final service = BitboxService(connectionStatusInterval: fastInterval);
      await service.dispose();
      await service.dispose();
      // No assertion beyond "no throw" — the contract is "safe to call
      // multiple times" so hot-restart code paths can be defensive.
    });
  });

  group('state-machine property — every observed traversal is valid', () {
    // Exhaustively pin "no impossible transition" for the canonical
    // operating sequences. The property is: for any sequence of
    // init/clear/signalDeviceLost, two consecutive emissions on the stream
    // must be a legal edge in the state machine declared in ADR 0001.
    final legalEdges = <Type, Set<Type>>{
      Disconnected: <Type>{Connecting, Disconnecting},
      Connecting: <Type>{Paired, Disconnected},
      Paired: <Type>{InUse, Lost, Disconnecting},
      InUse: <Type>{Paired, Lost, Disconnecting},
      Lost: <Type>{Disconnecting},
      Disconnecting: <Type>{Disconnected},
    };

    bool isValid(List<BitboxConnectionStatus> trail) {
      for (var i = 1; i < trail.length; i++) {
        final prev = trail[i - 1].runtimeType;
        final next = trail[i].runtimeType;
        if (prev == next) continue; // de-dup or replay-last; trivially valid.
        final allowed = legalEdges[prev];
        if (allowed == null || !allowed.contains(next)) return false;
      }
      return true;
    }

    test('init → clear', () {
      fakeAsync((async) {
        final service = BitboxService(connectionStatusInterval: fastInterval);
        addTearDown(service.dispose);
        final observed = observe(service);
        pairServiceSync(async, service);
        service.clear();
        async.flushMicrotasks();
        expect(
          isValid(observed),
          isTrue,
          reason: 'observed: ${observed.map((s) => s.runtimeType).toList()}',
        );
      });
    });

    test('init → signalDeviceLost → clear', () {
      fakeAsync((async) {
        final service = BitboxService(connectionStatusInterval: fastInterval);
        addTearDown(service.dispose);
        final observed = observe(service);
        pairServiceSync(async, service);
        service.signalDeviceLost(LostReason.signQueueTimeout);
        async.flushMicrotasks();
        service.clear();
        async.flushMicrotasks();
        expect(
          isValid(observed),
          isTrue,
          reason: 'observed: ${observed.map((s) => s.runtimeType).toList()}',
        );
      });
    });

    test('init → clear → init → clear (cycle stays legal)', () {
      fakeAsync((async) {
        final service = BitboxService(connectionStatusInterval: fastInterval);
        addTearDown(service.dispose);
        final observed = observe(service);
        pairServiceSync(async, service);
        service.clear();
        async.flushMicrotasks();
        pairServiceSync(async, service);
        service.clear();
        async.flushMicrotasks();
        expect(
          isValid(observed),
          isTrue,
          reason: 'observed: ${observed.map((s) => s.runtimeType).toList()}',
        );
      });
    });

    test('observer-driven device vanish keeps the traversal legal', () {
      fakeAsync((async) {
        final service = BitboxService(connectionStatusInterval: fastInterval);
        addTearDown(service.dispose);
        final observed = observe(service);
        pairServiceSync(async, service);
        platform.when(
          SimulatedBitboxMethod.getDevices,
          (_) async => const <BitboxDevice>[],
        );
        service.startConnectionStatusObserver();
        async.elapse(observerSettleTime);
        expect(
          isValid(observed),
          isTrue,
          reason: 'observed: ${observed.map((s) => s.runtimeType).toList()}',
        );
      });
    });
  });

  group('multi-subscriber + cancel semantics', () {
    test('two simultaneous subscribers receive the same traversal', () {
      // Broadcast contract: every active subscription sees every transition
      // in the same order. Without this, a sub-Cubit could miss a Lost the
      // parent Cubit observed and continue to treat the device as live.
      fakeAsync((async) {
        final service = BitboxService(connectionStatusInterval: fastInterval);
        addTearDown(service.dispose);
        final a = observe(service);
        final b = observe(service);
        pairServiceSync(async, service);
        service.signalDeviceLost(LostReason.signQueueTimeout);
        async.flushMicrotasks();
        service.clear();
        async.flushMicrotasks();

        final aTypes = a.map((s) => s.runtimeType).toList();
        final bTypes = b.map((s) => s.runtimeType).toList();
        expect(
          aTypes,
          equals(bTypes),
          reason: 'broadcast subscribers must observe identical traversals',
        );
        expect(
          aTypes,
          containsAllInOrder(<Type>[
            Paired,
            Lost,
            Disconnecting,
            Disconnected,
          ]),
        );
      });
    });

    test('cancelled subscriptions stop receiving transitions', () {
      // Subscription leak guard: a cubit's `close()` must let go of its
      // status subscription. After `cancel()` no further events should
      // reach the closed-over collector.
      fakeAsync((async) {
        final service = BitboxService(connectionStatusInterval: fastInterval);
        addTearDown(service.dispose);

        final received = <BitboxConnectionStatus>[];
        final sub = service.status.listen(received.add);
        async.flushMicrotasks();
        final countBeforeCancel = received.length;

        sub.cancel();
        pairServiceSync(async, service);
        service.clear();
        async.flushMicrotasks();

        expect(
          received.length,
          countBeforeCancel,
          reason: 'cancelled subscriptions must not accrue events',
        );
      });
    });
  });

  group('clear() observable post-conditions', () {
    test('clear() empties _credentialsByAddress (next getCredentials is fresh)', () {
      fakeAsync((async) {
        final service = BitboxService(connectionStatusInterval: fastInterval);
        addTearDown(service.dispose);
        pairServiceSync(async, service);

        final original = service.getCredentials(
          '0x000000000000000000000000000000000000dead',
        );
        expect(original.isConnected, isTrue);

        service.clear();
        async.flushMicrotasks();

        final after = service.getCredentials(
          '0x000000000000000000000000000000000000dead',
        );
        expect(identical(after, original), isFalse, reason: 'clear() drops cached credentials');
        expect(after.isConnected, isFalse, reason: 'fresh credentials before re-init are detached');
      });
    });

    test('clear() detaches the BitboxManager from every credentials in the map', () {
      fakeAsync((async) {
        final service = BitboxService(connectionStatusInterval: fastInterval);
        addTearDown(service.dispose);
        pairServiceSync(async, service);

        final a = service.getCredentials(
          '0x000000000000000000000000000000000000dead',
        );
        final b = service.getCredentials(
          '0x000000000000000000000000000000000000beef',
        );
        expect(a.isConnected, isTrue);
        expect(b.isConnected, isTrue);

        service.clear();
        async.flushMicrotasks();

        expect(
          a.isConnected,
          isFalse,
          reason: 'clear() must null-out the manager on every credentials',
        );
        expect(b.isConnected, isFalse);
      });
    });

    test('clear() final status is Disconnected (terminal of the walk)', () {
      fakeAsync((async) {
        final service = BitboxService(connectionStatusInterval: fastInterval);
        addTearDown(service.dispose);
        pairServiceSync(async, service);
        service.clear();
        async.flushMicrotasks();
        expect(service.currentStatus, equals(const Disconnected()));
      });
    });
  });
}
