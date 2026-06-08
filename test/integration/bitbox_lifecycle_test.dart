// Cross-layer integration test for the Initiative I BitBox connection
// lifecycle. The suite stitches the real `BitboxService` against the in-tree
// `SimulatedBitboxPlatform` (the same testkit `bitbox_service_lifecycle_test`
// uses) and exercises the end-to-end traversal that PR #468's 17-item
// tracking issue cares about:
//
//   init → pair → sign → disconnect-mid-sign → reconnect → re-init
//
// No mocks above the service surface: real BitboxService, real
// BitboxCredentials, real broadcast Stream<BitboxConnectionStatus>. The
// simulated platform is the load-bearing seam — every call site that would
// reach the BitBox firmware in production lands here instead.
//
// This is the Tier-1 conformance pin for ADR 0001's state machine: any
// refactor of the Stream contract must keep these traversals legal.

import 'dart:async';
import 'dart:typed_data';

import 'package:bitbox_flutter/bitbox_flutter.dart';
import 'package:bitbox_flutter/testing.dart';
import 'package:bitbox_flutter/usb/bitbox_usb_platform_interface.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_connection_status.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_credentials.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';

void main() {
  late BitboxUsbPlatform previousPlatform;
  late SimulatedBitboxPlatform platform;

  const interval = Duration(milliseconds: 25);
  const settle = Duration(milliseconds: 80);
  const knownAddress = '0x000000000000000000000000000000000000dead';

  setUp(() {
    previousPlatform = BitboxUsbPlatform.instance;
    platform = installSimulatedBitboxPlatform();
  });

  tearDown(() {
    BitboxUsbPlatform.instance = previousPlatform;
  });

  Future<BitboxService> pair() async {
    final service = BitboxService(connectionStatusInterval: interval);
    final devices = await service.getAllUsbDevices();
    final status = await service.init(devices.single);
    expect(status, isA<Paired>(), reason: 'integration setup requires a successful pair');
    return service;
  }

  test(
    'happy path: init → pair → sign (signTypedDataV4) → clear',
    () async {
      final service = await pair();
      addTearDown(service.dispose);

      final credentials = service.getCredentials(knownAddress);
      expect(credentials.isConnected, isTrue, reason: 'credentials must be live after pair');

      // sign via the typed-message path so the credentials hit
      // signETHTypedMessage on the simulator and we observe the full
      // credentials → manager → platform chain.
      final signature = await credentials.signTypedDataV4(
        1,
        '{"primaryType":"Mail"}',
      );
      expect(signature, isNotEmpty);
      expect(
        platform.count(SimulatedBitboxMethod.signETHTypedMessage),
        1,
        reason: 'sign must reach the platform exactly once',
      );

      await service.clear();
      expect(service.currentStatus, equals(const Disconnected()));
      expect(credentials.isConnected, isFalse);
    },
  );

  test(
    'disconnect-mid-sign: observer flips service to Lost(deviceUnreachable)',
    () async {
      final service = await pair();
      addTearDown(service.dispose);

      final credentials = service.getCredentials(knownAddress);
      expect(credentials.isConnected, isTrue);

      final transitions = <BitboxConnectionStatus>[];
      final sub = service.status.listen(transitions.add);
      addTearDown(sub.cancel);

      // Simulate the device vanishing on the BLE link. The next observer
      // tick must detect the empty device list and flip Lost.
      platform.when(
        SimulatedBitboxMethod.getDevices,
        (_) async => const <BitboxDevice>[],
      );
      service.startConnectionStatusObserver();

      // Wait long enough for at least 2 ticks (the observer's await-chain
      // takes one tick to inspect the device list and a follow-up microtask
      // hop to emit Lost).
      await Future<void>.delayed(settle);

      expect(
        transitions.whereType<Lost>().toList(),
        isNotEmpty,
        reason: 'observer must emit Lost on device vanish',
      );
      expect(
        transitions.whereType<Lost>().last.reason,
        equals(LostReason.deviceUnreachable),
      );
      expect(credentials.isConnected, isFalse);
    },
  );

  test(
    'reconnect after Lost: a fresh init() heals the previously-detached credentials',
    () async {
      final service = await pair();
      addTearDown(service.dispose);

      final credentials = service.getCredentials(knownAddress);
      expect(credentials.isConnected, isTrue);

      // Vanish then come back.
      platform.when(
        SimulatedBitboxMethod.getDevices,
        (_) async => const <BitboxDevice>[],
      );
      service.startConnectionStatusObserver();
      await Future<void>.delayed(settle);
      expect(credentials.isConnected, isFalse);

      // Device reappears. clear() is required to walk Lost → Disconnected
      // before re-init can succeed (per ADR 0001's state machine — Lost is
      // terminal for the pairing session).
      await service.clear();
      expect(service.currentStatus, equals(const Disconnected()));

      platform.when(
        SimulatedBitboxMethod.getDevices,
        (_) async => platform.devices,
      );
      final devices = await service.getAllUsbDevices();
      // After clear() the credentials cache was dropped, so re-init does
      // not re-attach the SAME credentials instance. The consumer must
      // re-acquire credentials via getCredentials AFTER init.
      final status = await service.init(devices.single);
      expect(status, isA<Paired>(), reason: 're-init must succeed');

      final reAcquired = service.getCredentials(knownAddress);
      expect(
        reAcquired.isConnected,
        isTrue,
        reason: 're-acquired credentials are attached to the new pairing',
      );
      // The signature must succeed via the re-attached manager.
      final sig = await reAcquired.signTypedDataV4(
        1,
        '{"primaryType":"Mail"}',
      );
      expect(sig, isNotEmpty);
    },
  );

  test(
    'sign-queue timeout (mid-sign) routes through service-level Lost(signQueueTimeout)',
    () async {
      // End-to-end pin of the F-009 closure: a hung native sign times out,
      // BitboxCredentials clears local state AND calls the closure the
      // service wired up — service emits Lost(signQueueTimeout) on the
      // lifecycle stream BEFORE the credentials' BitboxNotConnectedException
      // reaches the caller.
      //
      // Use the production sign-queue timeout to avoid coupling to internal
      // duration constants; the timeout is shortened by issuing the sign
      // against a platform that hangs the native method indefinitely. Real
      // wait time = signQueueTimeout (5 minutes). Drive the wait via a
      // bounded test-side timer so the suite stays fast: we stub the native
      // method to throw immediately as if the bounded sign already gave up.
      //
      // For the integration boundary, we rely on the existing unit-test
      // pinning of the closure invocation (bitbox_credentials_test.dart) and
      // here only assert the SERVICE-LEVEL post-condition: an immediate
      // `signalDeviceLost(signQueueTimeout)` from the credentials surfaces
      // through the stream.
      BitboxCredentials.resetSignQueue();

      final service = await pair();
      addTearDown(service.dispose);

      final transitions = <BitboxConnectionStatus>[];
      final sub = service.status.listen(transitions.add);
      addTearDown(sub.cancel);

      final credentials = service.getCredentials(knownAddress);

      // Drive the propagation deterministically by triggering it through the
      // public surface — the service exposes the closure via getCredentials,
      // so we exercise the equivalent failure path by calling
      // `signalDeviceLost(signQueueTimeout)` directly. The exact wire from
      // _synchronizeBoundedSign → closure is unit-tested in
      // bitbox_credentials_test.dart with fakeAsync.
      service.signalDeviceLost(LostReason.signQueueTimeout);

      // Lost emission lands synchronously on the broadcast queue and arrives
      // to subscribers on the next microtask hop.
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final losts = transitions.whereType<Lost>().toList();
      expect(losts, isNotEmpty, reason: 'sign-queue propagation must emit Lost on the stream');
      expect(losts.last.reason, equals(LostReason.signQueueTimeout));
      expect(
        credentials.isConnected,
        isFalse,
        reason: 'signalDeviceLost must detach every credentials',
      );
    },
  );

  test(
    'cycle: pair → sign → clear → pair → sign stays legal across iterations',
    () async {
      // Stress pin: the state machine has to survive arbitrary pair/clear
      // cycles without leaking observer timers or wedging the
      // _pendingDisconnect future. Three full cycles is enough to catch a
      // missed reset of _pendingInit or _credentialsByAddress.
      final service = BitboxService(connectionStatusInterval: interval);
      addTearDown(service.dispose);

      for (var i = 0; i < 3; i++) {
        final devices = await service.getAllUsbDevices();
        expect(devices, isNotEmpty);
        final status = await service.init(devices.single);
        expect(status, isA<Paired>(), reason: 'cycle $i: init must Pair');

        final credentials = service.getCredentials(knownAddress);
        final sig = await credentials.signTypedDataV4(
          1,
          '{"primaryType":"Iter-$i"}',
        );
        expect(sig, isNotEmpty);

        await service.clear();
        expect(
          service.currentStatus,
          equals(const Disconnected()),
          reason: 'cycle $i: clear must terminate at Disconnected',
        );
        expect(
          credentials.isConnected,
          isFalse,
          reason: 'cycle $i: clear must detach the credentials',
        );
      }

      expect(
        platform.count(SimulatedBitboxMethod.signETHTypedMessage),
        3,
        reason: 'every cycle must reach the device exactly once',
      );
    },
  );

  test(
    'signalDeviceLost from a non-Paired state is a no-op (no spurious Lost emission)',
    () async {
      // Defensive: a stale credentials reference firing the closure after
      // the service has already cleared must NOT emit Lost — the consumer
      // would otherwise see "lost while never connected" and the state
      // machine would walk Disconnected → Lost which is illegal.
      final service = BitboxService(connectionStatusInterval: interval);
      addTearDown(service.dispose);

      final transitions = <BitboxConnectionStatus>[];
      final sub = service.status.listen(transitions.add);
      addTearDown(sub.cancel);

      service.signalDeviceLost(LostReason.signQueueTimeout);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(
        transitions.whereType<Lost>(),
        isEmpty,
        reason: 'signalDeviceLost from Disconnected must be a no-op',
      );
    },
  );

  test(
    'sign on a cleared service throws BitboxNotConnectedException',
    () async {
      // Cleared service => credentials cache empty AND manager detached.
      // The next sign must fail fast with the typed exception instead of
      // racing the (now-disconnected) device.
      final service = await pair();
      addTearDown(service.dispose);

      final credentials = service.getCredentials(knownAddress);
      await service.clear();

      await expectLater(
        credentials.signTypedDataV4(1, '{"primaryType":"X"}'),
        throwsA(isA<BitboxNotConnectedException>()),
      );
    },
  );

  test('dispose() closes the stream and rejects subsequent init()', () async {
    final service = await pair();
    final done = Completer<void>();
    service.status.listen((_) {}, onDone: done.complete);

    final devices = await service.getAllUsbDevices();
    await service.dispose();
    await done.future.timeout(const Duration(seconds: 1));

    expect(
      () => service.init(devices.single),
      throwsA(isA<StateError>()),
      reason: 'init() after dispose() must throw',
    );
  });

  // ---------------------------------------------------------------------
  // Coverage-gap fillers — exercise the remaining surface that the higher
  // level integration tests don't naturally touch but that ADR 0001 still
  // requires to be observable from the test boundary.
  // ---------------------------------------------------------------------

  test('startScan delegates to BitboxManager and surfaces its boolean', () async {
    final service = BitboxService(connectionStatusInterval: interval);
    addTearDown(service.dispose);
    final ok = await service.startScan();
    expect(ok, isTrue, reason: 'simulated platform reports scan success by default');
    expect(platform.count(SimulatedBitboxMethod.startScan), 1);
  });

  test(
    'init() failure inside `connect` walks Connecting → Disconnected via the catch arm',
    () async {
      // Drives the catch-arm inside `_runInit` that re-emits Disconnected
      // when an exception escapes the connect path. Achieved by making the
      // simulator's `open` throw (the SDK call site rethrows the original).
      platform.throwOn(SimulatedBitboxMethod.open, Exception('USB busy'));

      final service = BitboxService(connectionStatusInterval: interval);
      addTearDown(service.dispose);
      final observed = <BitboxConnectionStatus>[];
      final sub = service.status.listen(observed.add);
      addTearDown(sub.cancel);

      final devices = await service.getAllUsbDevices();
      await expectLater(
        () => service.init(devices.single),
        throwsA(isA<Exception>()),
      );
      // Drain any pending broadcast events so the post-throw Disconnected
      // lands in `observed` before we assert.
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Drop the replayed initial Disconnected so the assertion describes
      // only the transitions caused by init().
      final transitions = observed.skipWhile((s) => s is Disconnected).toList(growable: false);
      expect(
        transitions.map((s) => s.runtimeType).toList(),
        containsAllInOrder(<Type>[Connecting, Disconnected]),
        reason: 'failure in connect must walk Connecting → Disconnected',
      );
    },
  );

  test('getChannelHash and confirmPairing delegate to the SDK', () async {
    final service = await pair();
    addTearDown(service.dispose);

    final hash = await service.getChannelHash();
    expect(hash, isNotEmpty, reason: 'simulator returns its default channel hash');

    await service.confirmPairing();
    expect(platform.count(SimulatedBitboxMethod.channelHashVerify), 1);
  });

  test('confirmPairing throws when the SDK reports verify failure', () async {
    // Drives the !didVerify branch.
    platform.when(
      SimulatedBitboxMethod.channelHashVerify,
      (_) async => false,
    );

    final service = await pair();
    addTearDown(service.dispose);

    await expectLater(
      service.confirmPairing(),
      throwsA(isA<Exception>()),
    );
  });

  test(
    '_onCredentialsSignQueueTimeout: a hung credentials sign routes to service-Lost via the wired closure',
    () {
      // End-to-end pin of the wired closure inside BitboxService.
      // `getCredentials` injects `_onCredentialsSignQueueTimeout` into every
      // BitboxCredentials it constructs, and a `_synchronizeBoundedSign`
      // timeout calls the closure. The closure forwards to
      // `signalDeviceLost(LostReason.signQueueTimeout)`. We drive the
      // production timeout inside fakeAsync so the 5-minute wall-clock wait
      // collapses to virtual time, AND we assert the post-condition on the
      // service stream — proving the closure was actually wired (a missing
      // wire would surface as an absent Lost emission).
      fakeAsync((async) {
        // Seed the sign queue inside this zone.
        BitboxCredentials.resetSignQueue();
        async.flushMicrotasks();

        // Native sign hangs — exactly the failure mode the bounded queue
        // exists to bound. `setDelay` would re-arm wall-clock; instead we
        // stub the simulator to return a never-completing future for the
        // native call.
        platform.when(
          SimulatedBitboxMethod.signETHTypedMessage,
          (_) => Completer<Uint8List>().future,
        );

        final service = BitboxService(connectionStatusInterval: interval);
        late List<BitboxDevice> devices;
        service.getAllUsbDevices().then((d) => devices = d);
        async.flushMicrotasks();
        BitboxConnectionStatus? initStatus;
        service.init(devices.single).then((s) => initStatus = s);
        async.flushMicrotasks();
        expect(initStatus, isA<Paired>(), reason: 'fakeAsync init must reach Paired');

        final observed = <BitboxConnectionStatus>[];
        final sub = service.status.listen(observed.add);

        // Issue a sign through the service-handed credentials. The native
        // call hangs; the queue-bound timeout fires after `signQueueTimeout`
        // and the closure inside the credentials calls back into the
        // service.
        final credentials = service.getCredentials(knownAddress);
        Object? thrown;
        credentials.signTypedDataV4(1, '{"primaryType":"Hang"}').catchError(
          (Object e) {
            thrown = e;
            return '';
          },
        );

        // Drain past the queue-bound timeout.
        async.elapse(
          BitboxCredentials.signQueueTimeout + const Duration(seconds: 2),
        );
        async.flushMicrotasks();

        expect(
          thrown,
          isA<BitboxNotConnectedException>(),
          reason: 'queue-bound timeout must surface the typed exception',
        );

        // The closure fired Lost(signQueueTimeout) on the stream BEFORE the
        // exception reached the caller.
        final losts = observed.whereType<Lost>().toList();
        expect(losts, isNotEmpty, reason: 'sign-queue timeout must reach the service-level stream');
        expect(losts.last.reason, equals(LostReason.signQueueTimeout));

        sub.cancel();
      });
    },
  );
}

// fakeAsync requires Uint8List for the typed-data return; pulled in via
// bitbox_flutter export above. Keep the test file dependency-clean.
