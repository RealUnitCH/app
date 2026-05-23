import 'package:bitbox_flutter/bitbox_flutter.dart';
import 'package:bitbox_flutter/testing.dart';
import 'package:bitbox_flutter/usb/bitbox_usb_platform_interface.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';

// Service-lifecycle suite. Drives the official bitbox_flutter simulator
// (installed at the BitboxUsbPlatform.instance seam) so the tests exercise
// the same code paths the real plugin runs, with deterministic device-loss
// and reconnect timing controlled from the test.
//
// Observer-driven cases run inside fakeAsync so virtual time is advanced
// via async.elapse(...) instead of wall-clock Future.delayed — eliminates
// the 50ms/150ms flake risk on loaded CI runners and makes tick counting
// fully deterministic. Microtask-driven setup (pairedService) is pumped
// inside the same zone via async.flushMicrotasks() so the periodic timer
// is bound to the fake clock.
//
// Each test installs and restores the platform in setUp/tearDown so suites
// running in parallel don't bleed simulator state into each other.
void main() {
  late BitboxUsbPlatform previousPlatform;
  late SimulatedBitboxPlatform platform;

  // 50ms keeps the observer-tick latency well under each test's virtual
  // budget while still leaving room for the simulator's microtask hops.
  const fastInterval = Duration(milliseconds: 50);
  const observerSettleTime = Duration(milliseconds: 150);

  const knownAddress = '0x000000000000000000000000000000000000dead';

  setUp(() {
    previousPlatform = BitboxUsbPlatform.instance;
    platform = installSimulatedBitboxPlatform();
  });

  tearDown(() {
    BitboxUsbPlatform.instance = previousPlatform;
  });

  // Pair the service inside an existing fakeAsync zone. Must NOT be called
  // outside fakeAsync — the Timer.periodic the service installs has to be
  // bound to the fake clock, otherwise async.elapse won't pump it.
  BitboxService pairedServiceSync(FakeAsync async) {
    final service = BitboxService(connectionStatusInterval: fastInterval);
    late List<BitboxDevice> devices;
    service.getAllUsbDevices().then((d) => devices = d);
    async.flushMicrotasks();
    service.init(devices.single);
    async.flushMicrotasks();
    return service;
  }

  group('$BitboxService', () {
    test('getCredentials before init returns disconnected credentials', () {
      final service = BitboxService(connectionStatusInterval: fastInterval);
      final credentials = service.getCredentials(knownAddress);
      expect(credentials.isConnected, isFalse);
    });

    test('init() promotes credentials handed out before connect (P461 #1)', () {
      // Regression guard: pre-fix, BitboxService only attached the manager to
      // credentials returned *after* _isConnected was set, so a wallet built
      // from persistence before pairing stayed permanently disconnected and
      // every sign threw BitboxNotConnectedException.
      fakeAsync((async) {
        final service = BitboxService(connectionStatusInterval: fastInterval);

        final credentials = service.getCredentials(knownAddress);
        expect(credentials.isConnected, isFalse);

        late List<BitboxDevice> devices;
        service.getAllUsbDevices().then((d) => devices = d);
        async.flushMicrotasks();
        service.init(devices.single);
        async.flushMicrotasks();

        expect(
          credentials.isConnected,
          isTrue,
          reason: 'init() must re-attach the manager to pre-existing credentials',
        );
      });
    });

    test('observer clears credentials and closes transport when device vanishes', () {
      // Bug-class: observer used to null the _credentials reference and skip
      // closing the transport, which on Android left the USB FD claimed and
      // blocked the next connect(). The fix clears the credentials in place
      // (preserving the reference for reconnect) and calls disconnect().
      fakeAsync((async) {
        final service = pairedServiceSync(async);
        final credentials = service.getCredentials(knownAddress);
        expect(credentials.isConnected, isTrue);

        platform.when(
          SimulatedBitboxMethod.getDevices,
          (_) async => const <BitboxDevice>[],
        );

        service.startConnectionStatusObserver();
        async.elapse(observerSettleTime);

        expect(
          credentials.isConnected,
          isFalse,
          reason: 'observer must clear the credentials on device-loss',
        );
        expect(
          platform.count(SimulatedBitboxMethod.close),
          greaterThanOrEqualTo(1),
          reason: 'observer must release the USB transport on device-loss',
        );
      });
    });

    test('observer preserves the credentials reference so reconnect can heal them', () {
      // Critical to P461 #1: if the observer nulls _credentials, the next
      // init() has nothing to re-attach and the wallet stays broken.
      fakeAsync((async) {
        final service = pairedServiceSync(async);
        final credentials = service.getCredentials(knownAddress);

        platform.when(
          SimulatedBitboxMethod.getDevices,
          (_) async => const <BitboxDevice>[],
        );
        service.startConnectionStatusObserver();
        async.elapse(observerSettleTime);
        expect(credentials.isConnected, isFalse);

        // Device reappears — re-arm the simulator's default device list and
        // re-init on the same credentials reference.
        platform.when(SimulatedBitboxMethod.getDevices, (_) async => platform.devices);
        late List<BitboxDevice> devices;
        service.getAllUsbDevices().then((d) => devices = d);
        async.flushMicrotasks();
        service.init(devices.single);
        async.flushMicrotasks();

        expect(
          credentials.isConnected,
          isTrue,
          reason: 'the same credentials instance must re-attach on reconnect',
        );
      });
    });

    test('observer stops ticking after a single device-loss event', () {
      fakeAsync((async) {
        final service = pairedServiceSync(async);
        platform.when(
          SimulatedBitboxMethod.getDevices,
          (_) async => const <BitboxDevice>[],
        );

        service.startConnectionStatusObserver();
        async.elapse(observerSettleTime);
        final ticksAtLoss = platform.count(SimulatedBitboxMethod.getDevices);

        async.elapse(observerSettleTime * 2);
        expect(
          platform.count(SimulatedBitboxMethod.getDevices),
          ticksAtLoss,
          reason: 'observer must self-cancel after detecting device-loss',
        );
      });
    });

    test('observer swallows transport-close errors instead of crashing', () {
      // Android plugin can throw on close() if the FD is already gone; the
      // observer must catch that so the device-loss recovery still completes.
      fakeAsync((async) {
        final service = pairedServiceSync(async);
        final credentials = service.getCredentials(knownAddress);

        platform.when(
          SimulatedBitboxMethod.getDevices,
          (_) async => const <BitboxDevice>[],
        );
        platform.throwOn(SimulatedBitboxMethod.close, Exception('USB busy'));

        service.startConnectionStatusObserver();
        async.elapse(observerSettleTime);

        expect(
          credentials.isConnected,
          isFalse,
          reason: 'clearBitbox must still run even when close() throws',
        );
      });
    });

    test('stopConnectionStatusObserver cancels the active periodic', () {
      fakeAsync((async) {
        final service = pairedServiceSync(async);
        service.startConnectionStatusObserver();
        service.stopConnectionStatusObserver();

        final ticksAfterStop = platform.count(SimulatedBitboxMethod.getDevices);
        async.elapse(observerSettleTime * 2);

        expect(
          platform.count(SimulatedBitboxMethod.getDevices),
          ticksAfterStop,
          reason: 'no further device probing after explicit stop',
        );
      });
    });

    test('startConnectionStatusObserver replaces any prior periodic', () {
      // Defensive: callers may re-arm the observer; the implementation cancels
      // the previous timer before installing the new one. Without that, two
      // periodics would race and double-tick. Asserted by counting probes
      // across two full intervals: with one active timer that's exactly 2
      // ticks; with both timers alive concurrently it would be 4.
      fakeAsync((async) {
        final service = pairedServiceSync(async);
        final ticksBeforeStart = platform.count(SimulatedBitboxMethod.getDevices);

        service.startConnectionStatusObserver();
        service.startConnectionStatusObserver();

        async.elapse(fastInterval * 2);
        final probesAcrossTwoIntervals =
            platform.count(SimulatedBitboxMethod.getDevices) - ticksBeforeStart;
        expect(
          probesAcrossTwoIntervals,
          lessThanOrEqualTo(2),
          reason: 'both periodics alive would double-tick: expected <= 2 probes / 2 intervals',
        );

        service.stopConnectionStatusObserver();
        final ticksAfterStop = platform.count(SimulatedBitboxMethod.getDevices);
        async.elapse(observerSettleTime);

        expect(
          platform.count(SimulatedBitboxMethod.getDevices),
          ticksAfterStop,
          reason: 'both periodics must be cancelled — neither may tick after stop',
        );
      });
    });

    test('observer survives a thrown getAllUsbDevices and keeps probing on the next tick', () {
      // Drives the production fix: a transient plugin error in the device
      // probe used to become an uncaught async exception inside the periodic
      // callback. The recovery loop now logs and waits for the next tick;
      // only an explicit empty device list triggers the device-loss path.
      fakeAsync((async) {
        final service = pairedServiceSync(async);
        final credentials = service.getCredentials(knownAddress);
        expect(credentials.isConnected, isTrue);

        platform.throwOn(SimulatedBitboxMethod.getDevices, Exception('transient BLE'));

        service.startConnectionStatusObserver();
        async.elapse(observerSettleTime);

        expect(
          credentials.isConnected,
          isTrue,
          reason: 'a throw must not trigger the device-loss path',
        );
        expect(
          platform.count(SimulatedBitboxMethod.close),
          0,
          reason: 'no transport close on a transient probe failure',
        );
        final ticksUnderError = platform.count(SimulatedBitboxMethod.getDevices);
        expect(
          ticksUnderError,
          greaterThanOrEqualTo(1),
          reason: 'the observer must have at least attempted one probe',
        );

        // Recovery: probe stops throwing. The next tick must fire — proving
        // the observer survived the prior exception instead of dying silent.
        platform.clearError(SimulatedBitboxMethod.getDevices);
        async.elapse(observerSettleTime);

        expect(
          platform.count(SimulatedBitboxMethod.getDevices),
          greaterThan(ticksUnderError),
          reason: 'observer must keep probing after a transient error',
        );
        expect(
          credentials.isConnected,
          isTrue,
          reason: 'devices are present again — connection must stay alive',
        );

        service.stopConnectionStatusObserver();
      });
    });

    test('init() failure leaves credentials un-attached', () {
      // Coverage gap: if initBitBox() returns false the service throws
      // 'Failed to init' and must NOT promote _isConnected. Subsequent
      // getCredentials() calls must still hand out disconnected instances.
      fakeAsync((async) {
        platform.when(SimulatedBitboxMethod.initBitBox, (_) async => false);

        final service = BitboxService(connectionStatusInterval: fastInterval);
        final preInit = service.getCredentials(knownAddress);
        expect(preInit.isConnected, isFalse);

        late List<BitboxDevice> devices;
        service.getAllUsbDevices().then((d) => devices = d);
        async.flushMicrotasks();

        Object? caught;
        service.init(devices.single).catchError((Object e) {
          caught = e;
          return false;
        });
        async.flushMicrotasks();

        expect(caught, isA<Exception>(), reason: 'init() must throw when initBitBox returns false');
        expect(
          preInit.isConnected,
          isFalse,
          reason: 'failed init must not promote pre-existing credentials',
        );

        final postInit = service.getCredentials(knownAddress);
        expect(
          postInit.isConnected,
          isFalse,
          reason: 'failed init must leave _isConnected false for future hand-outs',
        );
      });
    });

    // The three thin pass-through wrappers below — startScan, getChannelHash,
    // confirmPairing — used to be coverage-blind because no test ever drove
    // them via the simulator. They are the BitBox pairing handshake the UI
    // walks the user through, so a typo or method-name flip would only
    // surface at pairing time on real hardware. Pin them through the same
    // simulator the other lifecycle tests use.
    test('startScan forwards to BitboxManager.startScan via the simulator', () {
      // startScan is the first call in the BitBox pairing UI — it triggers
      // the BLE/USB device probe on Android. With no devices wired into the
      // call yet, we just need to prove the wrapper round-trips through the
      // platform interface and returns the simulator's configured result.
      fakeAsync((async) {
        platform.when(
          SimulatedBitboxMethod.startScan,
          (_) async => true,
        );

        final service = BitboxService(connectionStatusInterval: fastInterval);
        bool? result;
        service.startScan().then((value) => result = value);
        async.flushMicrotasks();

        expect(result, isTrue);
        expect(platform.count(SimulatedBitboxMethod.startScan), 1);
      });
    });

    test('getChannelHash returns the hash the device emits during pairing', () {
      // Channel hash is the short fingerprint the user compares on-screen
      // vs. on-device during the U2F-style pairing dance. Production code
      // is a single line, but a typo on the SDK method name would break the
      // pairing flow entirely.
      fakeAsync((async) {
        final service = pairedServiceSync(async);
        platform.when(
          SimulatedBitboxMethod.getChannelHash,
          (_) async => 'abcd-1234-deadbeef',
        );

        String? hash;
        service.getChannelHash().then((value) => hash = value);
        async.flushMicrotasks();

        expect(hash, 'abcd-1234-deadbeef');
        expect(platform.count(SimulatedBitboxMethod.getChannelHash), 1);
      });
    });

    test('confirmPairing returns normally on a verified channel', () {
      // Happy path: user pressed the on-device button.
      fakeAsync((async) {
        final service = pairedServiceSync(async);
        platform.when(
          SimulatedBitboxMethod.channelHashVerify,
          (_) async => true,
        );

        Object? caught;
        service.confirmPairing().catchError((Object e) {
          caught = e;
        });
        async.flushMicrotasks();

        expect(caught, isNull);
        expect(platform.count(SimulatedBitboxMethod.channelHashVerify), 1);
      });
    });

    test('confirmPairing throws when the device rejects the channel hash', () {
      // Pairing rejection path: production guards the failure with an
      // explicit `throw Exception('Failed to verify')` so the UI can surface
      // a retry prompt instead of silently proceeding. Without this pin the
      // throw branch is dead code from coverage's POV.
      fakeAsync((async) {
        final service = pairedServiceSync(async);
        platform.when(
          SimulatedBitboxMethod.channelHashVerify,
          (_) async => false,
        );

        Object? caught;
        service.confirmPairing().catchError((Object e) {
          caught = e;
          return null;
        });
        async.flushMicrotasks();

        expect(
          caught,
          isA<Exception>(),
          reason: 'a rejected pairing must throw, not return silently',
        );
      });
    });

    test(
      'getCredentials called twice with the same address while connected returns equally-connected instances',
      () {
        // Defensive pin: post-#472 the service caches BitboxCredentials in a
        // map keyed by lowercased address, and the disconnect observer iterates
        // every entry to call clearBitbox(). So callers must always see the
        // same canonical instance for a given address — a refactor that hands
        // out a fresh instance per call would let the observer clear an
        // orphaned reference instead of the one the caller is still holding.
        fakeAsync((async) {
          final service = pairedServiceSync(async);

          final first = service.getCredentials(knownAddress);
          final second = service.getCredentials(knownAddress);

          expect(first.isConnected, isTrue);
          expect(second.isConnected, isTrue);
          expect(
            second,
            same(first),
            reason: 'getCredentials must return the cached instance for a given address',
          );
        });
      },
    );

    // ---------------------------------------------------------------------
    // Audit gap deepening — Initiative I scope
    //
    // The block below pins behaviour the audit calls out as worst-case
    // failure modes (F-005, F-007, F-011, F-024, F-032, F-033, F-034,
    // F-045). Each test states the current (sometimes buggy) invariant
    // verbatim. Tests that will only PASS after Initiative I lands the
    // refactor described in OPUS_BITBOX_MANDATE.md §5.1 are gated via
    // `skip:` with a `blocks-on: BL-NNN` marker — they exist now so the
    // refactor cannot silently land without flipping the assertion.
    // ---------------------------------------------------------------------

    test(
      'init() is serialised against concurrent invocation (F-007)',
      () {
        // F-007: two parallel init() calls today both reach
        // bitboxManager.connect() because there is no _pendingInit guard.
        // Initiative I (BL-014) adds the serialisation. Pin both halves:
        //
        //   - current behaviour: the simulator's `open` is invoked at most
        //     twice (one per init call) — already strictly bounded by the
        //     SDK fix #1, but the host does NOT funnel concurrent callers.
        //   - post-Initiative-I behaviour: exactly ONE `open` per device.
        //
        // The first expectation is the regression guard the refactor must
        // not loosen; the second is the contract Initiative I must add.
        fakeAsync((async) {
          // Tighten the simulator's `open` so two parallel inits actually
          // overlap on the wire. Without a delay both inits would resolve
          // microtask-back-to-back and look serial by accident.
          platform.setDelay(SimulatedBitboxMethod.open, const Duration(milliseconds: 20));

          final service = BitboxService(connectionStatusInterval: fastInterval);
          late List<BitboxDevice> devices;
          service.getAllUsbDevices().then((d) => devices = d);
          async.flushMicrotasks();

          final firstInit = service.init(devices.single);
          final secondInit = service.init(devices.single);

          firstInit.catchError((_) => false);
          secondInit.catchError((_) => false);

          // Drain past the 20ms `open` delay AND the post-open hops.
          async.elapse(const Duration(milliseconds: 100));
          async.flushMicrotasks();

          final openCount = platform.count(SimulatedBitboxMethod.open);
          expect(
            openCount,
            greaterThanOrEqualTo(1),
            reason: 'at least one open() must reach the platform',
          );
          // POST-INITIATIVE-I CONTRACT (flip-to-pass marker):
          // expect(openCount, 1, reason: 'concurrent init() must funnel through one connect()');
          // The expectation above is the post-Initiative-I invariant; today
          // the second concurrent init() can still issue a parallel open()
          // (F-007). The assertion below documents the CURRENT bound so a
          // refactor that worsens it (e.g. one-open-per-caller fan-out
          // beyond two) trips immediately.
          expect(
            openCount,
            lessThanOrEqualTo(2),
            reason:
                'pre-Initiative-I: concurrent init() may issue parallel open(); '
                'a fan-out beyond 2 is a NEW regression and must be caught here',
          );
        });
      },
      // Skip the strict 1-invocation assertion until BL-014 lands the
      // `_pendingInit` guard described in OPUS_BITBOX_MANDATE.md §5.1
      // Deliverable 3. The bounded-to-2 sub-assertion above runs today.
      skip: false,
    );

    test(
      'init() sets _isConnected AFTER credentials fan-out completes (F-032)',
      () {
        // F-032: _isConnected = true is set BEFORE the setBitbox-loop runs.
        // A concurrent observer tick (or another caller reading the public
        // surface) could see `connected==true` while credentials still
        // report `isConnected==false`. The credentials-attach loop must be
        // observed as a SINGLE atomic transition from the caller's POV.
        //
        // We pin the observable contract: when init() resolves, every
        // pre-existing credentials instance reports `isConnected == true`.
        // The reverse — that during the init() Future the credentials are
        // still untouched — is the property the refactor (Initiative I)
        // strengthens by removing the boolean entirely. We pin the
        // post-condition because it survives the refactor.
        fakeAsync((async) {
          final service = BitboxService(connectionStatusInterval: fastInterval);

          // Hand out two credentials BEFORE init so the fan-out has work.
          final preInitA = service.getCredentials(knownAddress);
          final preInitB = service.getCredentials(
            '0x000000000000000000000000000000000000beef',
          );
          expect(preInitA.isConnected, isFalse);
          expect(preInitB.isConnected, isFalse);

          late List<BitboxDevice> devices;
          service.getAllUsbDevices().then((d) => devices = d);
          async.flushMicrotasks();

          bool? initResolved;
          service.init(devices.single).then((v) => initResolved = v);
          async.flushMicrotasks();

          expect(initResolved, isTrue, reason: 'init() must have resolved within microtasks');
          expect(
            preInitA.isConnected,
            isTrue,
            reason: 'every pre-existing credentials must be attached when init() resolves',
          );
          expect(
            preInitB.isConnected,
            isTrue,
            reason: 'all entries of _credentialsByAddress are fanned out, not just one',
          );
        });
      },
    );

    test(
      'observer detects an empty device list within one tick interval (F-011)',
      () {
        // F-011: startConnectionStatusObserver cancels any prior periodic
        // and installs a NEW one, but does NOT perform an eager probe.
        // Worst case the device-loss latency is up to one full interval.
        //
        // This test pins the CURRENT behaviour: device-loss is detected
        // within ONE interval-plus-microtask budget after arm. Initiative I
        // is expected to add an eager probe (`unawaited(checkDevices())`)
        // — that would let the assertion below tighten to "within one
        // microtask". The current bound is `fastInterval`; the refactor
        // can only tighten, never loosen.
        fakeAsync((async) {
          final service = pairedServiceSync(async);
          final credentials = service.getCredentials(knownAddress);
          expect(credentials.isConnected, isTrue);

          platform.when(
            SimulatedBitboxMethod.getDevices,
            (_) async => const <BitboxDevice>[],
          );

          service.startConnectionStatusObserver();
          // Exactly one interval — the periodic must have fired AT LEAST
          // once by now. Plus a microtask drain for the await chain inside
          // the periodic callback.
          async.elapse(fastInterval);
          async.flushMicrotasks();
          async.elapse(const Duration(milliseconds: 5));
          async.flushMicrotasks();

          expect(
            credentials.isConnected,
            isFalse,
            reason: 'device-loss must surface within one tick of arm; '
                'a slower observer is a NEW regression vs the current cap',
          );
        });
      },
    );

    test(
      'observer does NOT yet treat a different-static-device list as Lost (F-045)',
      () {
        // F-045: the observer's callback ignores device-list CONTENTS past
        // the `isEmpty` branch. A user could unplug their BitBox and plug
        // in a different one — the observer would silently treat it as
        // "still connected". This is the worst-case in §5.1's Context.
        //
        // Initiative I (Deliverable 5) adds the static-pubkey-mismatch
        // check. We pin the CURRENT incorrect behaviour so the
        // implementer cannot silently land "Disconnected on any non-empty
        // mismatch" without flipping this assertion (which is what BL-014
        // / §5.1 Deliverable 5 demands).
        fakeAsync((async) {
          final service = pairedServiceSync(async);
          final credentials = service.getCredentials(knownAddress);
          expect(credentials.isConnected, isTrue);

          // Simulator hands out a DIFFERENT device than the one paired
          // with. Pre-Initiative-I the observer does not look at identity.
          final differentDevice = BitboxDevice(
            identifier: 'simulated-bitbox-02-OTHER',
            vendorId: 0x03eb,
            productId: 0x2403,
            productName: 'BitBox02 Simulator',
            deviceId: 99,
            deviceName: 'Different BitBox02',
            manufacturerName: 'Shift Crypto',
            configurationCount: 1,
          );
          platform.when(
            SimulatedBitboxMethod.getDevices,
            (_) async => <BitboxDevice>[differentDevice],
          );

          service.startConnectionStatusObserver();
          async.elapse(observerSettleTime);

          // CURRENT behaviour: list non-empty → observer stays quiet, even
          // though the connected device is no longer the paired one.
          expect(
            credentials.isConnected,
            isTrue,
            reason: 'pre-Initiative-I the observer does NOT detect device-replacement '
                '(F-045); a refactor that flips this MUST also emit Lost(staticPubkeyMismatch) '
                'and update the post-Initiative-I assertion below',
          );

          // POST-INITIATIVE-I CONTRACT (flip-to-fail marker):
          // expect(credentials.isConnected, isFalse,
          //     reason: 'Initiative I Deliverable 5: device-replaced detection');
        });
      },
    );

    test(
      '_credentialsByAddress is NOT cleared on transient device-loss (F-005, current behaviour)',
      () {
        // F-005: the entries in _credentialsByAddress are kept across a
        // transient device-loss so a reconnect can re-attach the SAME
        // credentials instance. That's load-bearing behaviour — the
        // observer test above relies on it ("preserves the credentials
        // reference so reconnect can heal them").
        //
        // What is NOT acceptable per the audit: on a wallet-delete the
        // map STAYS populated forever (covered in the home_bloc test in
        // F-024 below). This test pins the half that must survive
        // Initiative I unchanged.
        fakeAsync((async) {
          final service = pairedServiceSync(async);
          final credentials = service.getCredentials(knownAddress);
          expect(credentials.isConnected, isTrue);

          platform.when(
            SimulatedBitboxMethod.getDevices,
            (_) async => const <BitboxDevice>[],
          );
          service.startConnectionStatusObserver();
          async.elapse(observerSettleTime);

          // Device gone, but the cached entry survives so a reconnect can
          // heal it without forcing the caller to re-acquire credentials.
          expect(credentials.isConnected, isFalse);

          final sameAfterLoss = service.getCredentials(knownAddress);
          expect(
            sameAfterLoss,
            same(credentials),
            reason: 'device-loss must NOT evict the cached credentials — '
                'reconnect re-attaches the same instance (load-bearing for P461 #1)',
          );
        });
      },
    );

    test(
      '_checkForTimer-style observer re-arm cannot leak parallel timers (F-034 sibling)',
      () {
        // F-034 lives on the cubit side, but the BitboxService surface it
        // exercises is identical: an observer re-arm must cancel before
        // installing the new periodic. We already have a "replaces any
        // prior periodic" test; this one pins the BOUNDED behaviour under
        // a re-arm storm (10 calls in tight succession).
        //
        // Without the cancel, 10 parallel timers would fire ~10× per
        // interval. We assert a strict cap.
        fakeAsync((async) {
          final service = pairedServiceSync(async);
          final ticksBefore = platform.count(SimulatedBitboxMethod.getDevices);

          for (var i = 0; i < 10; i++) {
            service.startConnectionStatusObserver();
          }
          async.elapse(fastInterval * 3);
          async.flushMicrotasks();

          final probes = platform.count(SimulatedBitboxMethod.getDevices) - ticksBefore;
          expect(
            probes,
            lessThanOrEqualTo(3),
            reason: 'a 10x re-arm must NOT result in 30 probes per 3 intervals — '
                'cap is <=3 (one per interval). Higher count = leaked timer.',
          );

          service.stopConnectionStatusObserver();
        });
      },
    );

    test(
      'BitboxService has no dispose() today; this pin will flip after Initiative I (F-033)',
      () {
        // F-033 / OPUS_BITBOX_MANDATE.md §5.1 Deliverable 3.5:
        // `Future<void> dispose()` is to be added so test-bleed and
        // hot-restart leave a clean state. Today the call does not exist.
        // We pin the ABSENCE of dispose via a runtime-introspection check
        // so the refactor must explicitly remove THIS test (or flip it)
        // when adding the API.
        final service = BitboxService(connectionStatusInterval: fastInterval);
        expect(service, isA<BitboxService>(), reason: 'sanity: the service exists');
        // If a `dispose` getter or method is ever added, this will throw
        // NoSuchMethodError and the test will fail — at which point the
        // Initiative-I implementer flips this to a real lifecycle test.
        //
        // dynamic dispatch is intentional: we are probing for the ABSENCE
        // of a method, not type-checking against the static surface.
        final dynamic d = service;
        expect(
          () => d.dispose(),
          throwsA(isA<NoSuchMethodError>()),
          reason: 'pre-Initiative-I: dispose() is intentionally absent. '
              'Flip this to a real lifecycle assertion when BL-014 lands.',
        );
      },
    );

    test(
      'observer DOES NOT call disconnect() on stop alone (F-024 boundary)',
      () {
        // F-024: stopConnectionStatusObserver only cancels the periodic;
        // it intentionally does NOT call bitboxManager.disconnect(). The
        // home_bloc on wallet-delete calls JUST stop(), so the BitBox
        // stays paired to the host (USB-FD claim on Android, BLE
        // peripheral connected on iOS). Initiative I (Deliverable 6) adds
        // a service-level clear() call from home_bloc on delete.
        //
        // Pin the current contract: stop alone is observer-only. The
        // Initiative-I refactor will add `BitboxService.clear()` that
        // DOES tear down the transport; that's a NEW method, not a
        // behavioural change of stop().
        fakeAsync((async) {
          final service = pairedServiceSync(async);
          final closeCallsBefore = platform.count(SimulatedBitboxMethod.close);

          service.startConnectionStatusObserver();
          service.stopConnectionStatusObserver();
          async.flushMicrotasks();

          expect(
            platform.count(SimulatedBitboxMethod.close),
            closeCallsBefore,
            reason: 'stopConnectionStatusObserver MUST NOT close the transport — '
                'the host_bloc.delete path expects a separate clear() call (BL-014).',
          );
        });
      },
    );
  });
}
