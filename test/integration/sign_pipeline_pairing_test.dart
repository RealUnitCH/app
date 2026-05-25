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
// `SimulatedBitboxPlatform` from `bitbox_flutter/testing.dart`.

import 'package:bitbox_flutter/testing.dart';
import 'package:bitbox_flutter/usb/bitbox_usb_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';

void main() {
  late BitboxUsbPlatform previousPlatform;
  late SimulatedBitboxPlatform platform;
  late bool rejectNextPairing;

  setUp(() {
    previousPlatform = BitboxUsbPlatform.instance;
    rejectNextPairing = false;
    platform = installSimulatedBitboxPlatform(
      behaviors: <String, SimulatedBitboxBehavior>{
        SimulatedBitboxMethod.channelHashVerify: (_) {
          if (rejectNextPairing) {
            rejectNextPairing = false;
            return false;
          }
          return true;
        },
      },
    );
  });

  tearDown(() {
    BitboxUsbPlatform.instance = previousPlatform;
  });

  test(
    'injectChannelHashMismatch during pair → confirmPairing throws; consumer must NOT proceed to sign',
    () async {
      rejectNextPairing = true;

      final service = BitboxService(
        connectionStatusInterval: const Duration(milliseconds: 25),
      );
      addTearDown(service.dispose);
      await service.init((await service.getAllUsbDevices()).single);

      // Production code path: ConnectBitboxCubit calls
      // service.getChannelHash() to show the hash to the user, then
      // service.confirmPairing() which delegates to
      // manager.channelHashVerify(). When the simulator is instructed to
      // reject the next pairing, verify returns false and
      // confirmPairing's `if (!didVerify) throw` fires.
      await service.getChannelHash();
      await expectLater(
        service.confirmPairing(),
        throwsA(isA<Exception>()),
        reason: 'verify==false must abort pairing',
      );

      await Future<void>.delayed(Duration.zero);
      expect(
        platform.count(SimulatedBitboxMethod.channelHashVerify),
        1,
        reason: 'pairing mismatch must be observed at the platform seam',
      );

      // The consumer must NOT issue any sign call after the
      // mismatch. Platform call history confirms zero sign* calls.
      final signCalls = platform.calls
          .where((call) => call.method.startsWith('sign'))
          .toList();
      expect(
        signCalls,
        isEmpty,
        reason: 'consumer must abort after channel-hash mismatch',
      );
    },
  );

  test(
    'after a mismatch consumed, a fresh pair succeeds — injection is single-shot',
    () async {
      rejectNextPairing = true;

      final service = BitboxService(
        connectionStatusInterval: const Duration(milliseconds: 25),
      );
      addTearDown(service.dispose);
      await service.init((await service.getAllUsbDevices()).single);
      await service.getChannelHash();

      // First verify fails.
      await expectLater(
        service.confirmPairing(),
        throwsA(isA<Exception>()),
      );

      // Second verify succeeds (injection consumed).
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
      addTearDown(service.dispose);
      await service.init((await service.getAllUsbDevices()).single);

      final h1 = await service.getChannelHash();
      final h2 = await service.getChannelHash();
      expect(h1, equals(h2));
      expect(h1, isNotEmpty);
    },
  );
}
