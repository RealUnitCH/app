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

        expect(credentials.isConnected, isFalse,
            reason: 'observer must clear the credentials on device-loss');
        expect(platform.count(SimulatedBitboxMethod.close), greaterThanOrEqualTo(1),
            reason: 'observer must release the USB transport on device-loss');
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

        expect(credentials.isConnected, isFalse,
            reason: 'clearBitbox must still run even when close() throws');
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

        expect(credentials.isConnected, isTrue,
            reason: 'a throw must not trigger the device-loss path');
        expect(platform.count(SimulatedBitboxMethod.close), 0,
            reason: 'no transport close on a transient probe failure');
        final ticksUnderError = platform.count(SimulatedBitboxMethod.getDevices);
        expect(ticksUnderError, greaterThanOrEqualTo(1),
            reason: 'the observer must have at least attempted one probe');

        // Recovery: probe stops throwing. The next tick must fire — proving
        // the observer survived the prior exception instead of dying silent.
        platform.clearError(SimulatedBitboxMethod.getDevices);
        async.elapse(observerSettleTime);

        expect(
          platform.count(SimulatedBitboxMethod.getDevices),
          greaterThan(ticksUnderError),
          reason: 'observer must keep probing after a transient error',
        );
        expect(credentials.isConnected, isTrue,
            reason: 'devices are present again — connection must stay alive');

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

        expect(caught, isA<Exception>(),
            reason: 'init() must throw when initBitBox returns false');
        expect(preInit.isConnected, isFalse,
            reason: 'failed init must not promote pre-existing credentials');

        final postInit = service.getCredentials(knownAddress);
        expect(postInit.isConnected, isFalse,
            reason: 'failed init must leave _isConnected false for future hand-outs');
      });
    });

    test('getCredentials called twice with the same address while connected returns equally-connected instances', () {
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
        expect(second, same(first),
            reason: 'getCredentials must return the cached instance for a given address');
      });
    });
  });
}
