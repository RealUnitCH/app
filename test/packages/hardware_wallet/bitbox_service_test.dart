import 'package:bitbox_flutter/bitbox_flutter.dart';
import 'package:bitbox_flutter/testing.dart';
import 'package:bitbox_flutter/usb/bitbox_usb_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';

// Service-lifecycle suite. Drives the official bitbox_flutter simulator
// (installed at the BitboxUsbPlatform.instance seam) so the tests exercise
// the same code paths the real plugin runs, with deterministic device-loss
// and reconnect timing controlled from the test.
//
// Each test installs and restores the platform in setUp/tearDown so suites
// running in parallel don't bleed simulator state into each other.
void main() {
  late BitboxUsbPlatform previousPlatform;
  late SimulatedBitboxPlatform platform;

  // 50ms keeps the observer-tick latency well under each test's wall-clock
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

  Future<BitboxService> pairedService() async {
    final service = BitboxService(connectionStatusInterval: fastInterval);
    final devices = await service.getAllUsbDevices();
    await service.init(devices.single);
    return service;
  }

  group('$BitboxService', () {
    test('getCredentials before init returns disconnected credentials', () {
      final service = BitboxService(connectionStatusInterval: fastInterval);
      final credentials = service.getCredentials(knownAddress);
      expect(credentials.isConnected, isFalse);
    });

    test('init() promotes credentials handed out before connect (P461 #1)', () async {
      // Regression guard: pre-fix, BitboxService only attached the manager to
      // credentials returned *after* _isConnected was set, so a wallet built
      // from persistence before pairing stayed permanently disconnected and
      // every sign threw BitboxNotConnectedException.
      final service = BitboxService(connectionStatusInterval: fastInterval);

      final credentials = service.getCredentials(knownAddress);
      expect(credentials.isConnected, isFalse);

      final devices = await service.getAllUsbDevices();
      await service.init(devices.single);

      expect(
        credentials.isConnected,
        isTrue,
        reason: 'init() must re-attach the manager to pre-existing credentials',
      );
    });

    test('observer clears credentials and closes transport when device vanishes', () async {
      // Bug-class: observer used to null the _credentials reference and skip
      // closing the transport, which on Android left the USB FD claimed and
      // blocked the next connect(). The fix clears the credentials in place
      // (preserving the reference for reconnect) and calls disconnect().
      final service = await pairedService();
      final credentials = service.getCredentials(knownAddress);
      expect(credentials.isConnected, isTrue);

      platform.when(
        SimulatedBitboxMethod.getDevices,
        (_) async => const <BitboxDevice>[],
      );

      service.startConnectionStatusObserver();
      await Future<void>.delayed(observerSettleTime);

      expect(credentials.isConnected, isFalse,
          reason: 'observer must clear the credentials on device-loss');
      expect(platform.count(SimulatedBitboxMethod.close), greaterThanOrEqualTo(1),
          reason: 'observer must release the USB transport on device-loss');
    });

    test('observer preserves the credentials reference so reconnect can heal them', () async {
      // Critical to P461 #1: if the observer nulls _credentials, the next
      // init() has nothing to re-attach and the wallet stays broken.
      final service = await pairedService();
      final credentials = service.getCredentials(knownAddress);

      platform.when(
        SimulatedBitboxMethod.getDevices,
        (_) async => const <BitboxDevice>[],
      );
      service.startConnectionStatusObserver();
      await Future<void>.delayed(observerSettleTime);
      expect(credentials.isConnected, isFalse);

      // Device reappears — clear the override so the simulator's default
      // device list applies again, then re-init.
      platform.clearError(SimulatedBitboxMethod.getDevices);
      platform.when(SimulatedBitboxMethod.getDevices, (_) async => platform.devices);
      final devices = await service.getAllUsbDevices();
      await service.init(devices.single);

      expect(
        credentials.isConnected,
        isTrue,
        reason: 'the same credentials instance must re-attach on reconnect',
      );
    });

    test('observer stops ticking after a single device-loss event', () async {
      final service = await pairedService();
      platform.when(
        SimulatedBitboxMethod.getDevices,
        (_) async => const <BitboxDevice>[],
      );

      service.startConnectionStatusObserver();
      await Future<void>.delayed(observerSettleTime);
      final ticksAtLoss = platform.count(SimulatedBitboxMethod.getDevices);

      await Future<void>.delayed(observerSettleTime * 2);
      expect(
        platform.count(SimulatedBitboxMethod.getDevices),
        ticksAtLoss,
        reason: 'observer must self-cancel after detecting device-loss',
      );
    });

    test('observer swallows transport-close errors instead of crashing', () async {
      // Android plugin can throw on close() if the FD is already gone; the
      // observer must catch that so the device-loss recovery still completes.
      final service = await pairedService();
      final credentials = service.getCredentials(knownAddress);

      platform.when(
        SimulatedBitboxMethod.getDevices,
        (_) async => const <BitboxDevice>[],
      );
      platform.throwOn(SimulatedBitboxMethod.close, Exception('USB busy'));

      service.startConnectionStatusObserver();
      await Future<void>.delayed(observerSettleTime);

      expect(credentials.isConnected, isFalse,
          reason: 'clearBitbox must still run even when close() throws');
    });

    test('stopConnectionStatusObserver cancels the active periodic', () async {
      final service = await pairedService();
      service.startConnectionStatusObserver();
      service.stopConnectionStatusObserver();

      final ticksAfterStop = platform.count(SimulatedBitboxMethod.getDevices);
      await Future<void>.delayed(observerSettleTime * 2);

      expect(
        platform.count(SimulatedBitboxMethod.getDevices),
        ticksAfterStop,
        reason: 'no further device probing after explicit stop',
      );
    });

    test('startConnectionStatusObserver replaces any prior periodic', () async {
      // Defensive: callers may re-arm the observer; the implementation cancels
      // the previous timer before installing the new one. Without that, two
      // periodics would race and double-tick.
      final service = await pairedService();
      service.startConnectionStatusObserver();
      service.startConnectionStatusObserver();

      await Future<void>.delayed(observerSettleTime);
      service.stopConnectionStatusObserver();

      final ticksAfterStop = platform.count(SimulatedBitboxMethod.getDevices);
      await Future<void>.delayed(observerSettleTime);

      expect(
        platform.count(SimulatedBitboxMethod.getDevices),
        ticksAfterStop,
        reason: 'both periodics must be cancelled — neither may tick after stop',
      );
    });
  });
}
