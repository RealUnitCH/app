// Initiative II — sign-pipeline pairing-mismatch detection.
//
// Pins the contract that BL-003 / BL-063 require: when the BitBox
// firmware reports `channelHashVerify=false`, the consumer must NOT
// continue with the sign. Until BL-003 lands the typed
// `PairingMismatchException`, the upstream observable is:
//
//   `BitboxService.confirmPairing()` throws on `verify == false`.
//
// This test pins that pre-condition end-to-end through the real
// `BitboxService` + `BitboxManager` + the platform-level
// `FakeBitboxCredentials` with `injectChannelHashMismatch()`.

import 'package:bitbox_flutter/testing.dart';
import 'package:bitbox_flutter/usb/bitbox_usb_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_credentials.dart';

void main() {
  late BitboxUsbPlatform previousPlatform;
  late FakeBitboxCredentials fake;

  setUp(() {
    previousPlatform = BitboxUsbPlatform.instance;
    fake = FakeBitboxCredentials()..install();
    BitboxCredentials.resetSignQueue();
  });

  tearDown(() {
    BitboxUsbPlatform.instance = previousPlatform;
    BitboxCredentials.resetSignQueue();
  });

  test(
    'injectChannelHashMismatch during pair → confirmPairing throws; consumer must NOT proceed to sign',
    () async {
      fake.injectChannelHashMismatch();

      final mismatchEvents = <FakeBitboxChannelHashMismatch>[];
      final sub = fake.events.listen((e) {
        if (e is FakeBitboxChannelHashMismatch) mismatchEvents.add(e);
      });

      final service = BitboxService(
        connectionStatusInterval: const Duration(milliseconds: 25),
      );
      await service.init((await service.getAllUsbDevices()).single);

      // Production code path: ConnectBitboxCubit calls
      // service.getChannelHash() to show the hash to the user, then
      // service.confirmPairing() which delegates to
      // manager.channelHashVerify(). When the fake's
      // injectChannelHashMismatch is active, verify returns false and
      // confirmPairing's `if (!didVerify) throw` fires.
      await service.getChannelHash();
      await expectLater(
        service.confirmPairing(),
        throwsA(isA<Exception>()),
        reason: 'verify==false must abort pairing',
      );

      await Future<void>.delayed(Duration.zero);
      expect(mismatchEvents, hasLength(1));

      // The consumer must NOT issue any sign call after the
      // mismatch. recordedInteractions confirms zero sign* calls.
      final signCalls = fake.recordedInteractions
          .where((i) => i.method.startsWith('sign'))
          .toList();
      expect(
        signCalls,
        isEmpty,
        reason: 'consumer must abort after channel-hash mismatch',
      );

      await sub.cancel();
    },
  );

  test(
    'after a mismatch consumed, a fresh pair succeeds — injection is single-shot',
    () async {
      fake.injectChannelHashMismatch();

      final service = BitboxService(
        connectionStatusInterval: const Duration(milliseconds: 25),
      );
      await service.init((await service.getAllUsbDevices()).single);
      await service.getChannelHash();

      // First verify fails.
      await expectLater(
        service.confirmPairing(),
        throwsA(isA<Exception>()),
      );

      // Second verify succeeds (injection consumed).
      // Reset the signQueue between attempts so the assertion is
      // independent of any in-flight sign that might have leaked
      // into the queue (none here, but defensive).
      BitboxCredentials.resetSignQueue();
      await service.confirmPairing();

      // No throw is the assertion — confirmPairing returns void.
    },
  );

  test(
    'getChannelHash on the consumer side returns a deterministic string the user can read out',
    () async {
      // The pairing UX requires a stable channel hash so the user can
      // compare the device's display to the host's display. The fake's
      // pubkey-derived hash is deterministic across runs given the
      // default pubkey, so this test pins the property without leaking
      // a concrete value (which would couple us to the fake's
      // implementation hashing scheme).
      final service = BitboxService(
        connectionStatusInterval: const Duration(milliseconds: 25),
      );
      await service.init((await service.getAllUsbDevices()).single);

      final h1 = await service.getChannelHash();
      final h2 = await service.getChannelHash();
      expect(h1, equals(h2));
      expect(h1, isNotEmpty);
    },
  );
}
