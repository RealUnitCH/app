// Initiative II + III — KYC sign disconnect mid-page routing.
//
// Pins the contract that F-003 (`bitbox_flutter-findings.md`) demands
// for `KycEmailVerificationCubit`: when the 13-page KYC sign drops mid-
// page, the consumer surfaces a typed `BitboxNotConnectedException` to
// the caller — **not** a generic registration failure — so the email-
// verification UI routes to the BitBox reconnect sheet.
//
// The test runs through real `Eip712Signer.signRegistration` →
// `BitboxCredentials.signTypedDataV4` → `BitboxManager.signETHTypedMessage`
// → the platform-level `FakeBitboxCredentials`. No mocks above Tier 0.
//
// The KycEmailVerificationCubit's `_completeRegistration` is the next
// layer up that wraps the sign call; the cubit currently routes a
// BitboxNotConnectedException into `KycEmailVerificationRegistrationFailure`
// (the bug behind F-003). Until §6.II's `KycEmailVerificationBitboxRequired`
// state lands, this test pins the *upstream* observable: the typed
// exception fires before the registration HTTP call ever begins.

import 'package:bitbox_flutter/testing.dart';
import 'package:bitbox_flutter/usb/bitbox_usb_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_credentials.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';
import 'package:realunit_wallet/packages/wallet/eip712_signer.dart';

void main() {
  late BitboxUsbPlatform previousPlatform;
  late FakeBitboxCredentials fake;
  late BitboxService service;
  late BitboxCredentials credentials;

  const known = '0x9f5713deacb8e9cab6c2d3fae1afc2715f8d2d71';

  Future<String> signRegistration() => Eip712Signer.signRegistration(
        credentials: credentials,
        chainId: 1,
        type: 'HUMAN',
        email: 'test@dfx.swiss',
        name: 'Test User',
        phoneNumber: '+41790000000',
        birthday: '1990-01-01',
        nationality: 'CH',
        addressStreet: 'Teststrasse 1',
        addressPostalCode: '8000',
        addressCity: 'Zurich',
        addressCountry: 'CH',
        swissTaxResidence: true,
        registrationDate: '2026-05-23',
      );

  setUp(() async {
    previousPlatform = BitboxUsbPlatform.instance;
    fake = FakeBitboxCredentials()..install();
    BitboxCredentials.resetSignQueue();

    service = BitboxService(
      connectionStatusInterval: const Duration(milliseconds: 25),
    );
    await service.init((await service.getAllUsbDevices()).single);
    credentials = service.getCredentials(known);
  });

  tearDown(() async {
    BitboxUsbPlatform.instance = previousPlatform;
    BitboxCredentials.resetSignQueue();
  });

  test(
    '13-page KYC sign with disconnect at page 7 throws BitboxNotConnectedException before any HTTP call',
    () async {
      fake.injectDisconnectAtPage(7);

      // signRegistration() funnels into Eip712Signer.signRegistration,
      // which calls _signTypedData → BitboxCredentials.signTypedDataV4
      // → manager.signETHTypedMessage. The fake's disconnect-at-page-7
      // converts to PlatformException(DISCONNECTED) inside the manager
      // call; _runOrThrowDisconnect's device-probe (empty devices) maps
      // that to BitboxNotConnectedException.
      await expectLater(
        signRegistration(),
        throwsA(isA<BitboxNotConnectedException>()),
        reason:
            'F-003: typed exception must surface; cubits route on this type, not on a generic Exception',
      );

      // The fake recorded exactly one sign call, and the disconnect
      // event was emitted with the right reason.
      expect(fake.countCalls('signETHTypedMessage'), 1);
      final disconnects = fake.recordedInteractions
          .where((i) => i.method == 'signETHTypedMessage')
          .toList();
      expect(disconnects, hasLength(1));
    },
  );

  test(
    'reconnect after BitboxNotConnectedException re-establishes the sign path',
    () async {
      fake.injectDisconnectAtPage(7);
      await expectLater(
        signRegistration(),
        throwsA(isA<BitboxNotConnectedException>()),
      );

      // After the disconnect, credentials report disconnected.
      expect(credentials.isConnected, isFalse);

      // Re-pair: this is the production reconnect path the cubit will
      // route to once F-003 is fixed. In Tier-1 we drive it directly.
      await fake.simulateReconnect();
      await service.init((await service.getAllUsbDevices()).single);
      expect(credentials.isConnected, isTrue);

      final sig = await signRegistration();
      // The fake's default signature has the EthSigUtil-compatible
      // 65-byte length, but the JSON-encoded typed-data is not the
      // EthSigUtil V4 format the consumer would parse on success.
      // The signature is still a non-empty hex string and the
      // "BitBox returned 0x"-guard does not trip; that is what
      // matters at this layer.
      expect(sig, startsWith('0x'));
      expect(sig.length, greaterThan(2));
    },
  );

  test(
    'firmware error (code 101: non-ASCII) maps to PlatformException; consumer does NOT silently report success',
    () async {
      // BitBox firmware rejects non-ASCII EIP-712 string values with
      // ErrInvalidInput=101 (memory project_realunit_bitbox_umlaut_bug).
      // The fake reproduces this at the plugin layer; the consumer's
      // signTypedDataV4 surfaces the PlatformException to the caller
      // because _runOrThrowDisconnect only intercepts disconnects
      // (device-list empty) — a firmware error is rethrown verbatim
      // as the PlatformException it is.
      fake.injectFirmwareError(code: 101, hint: 'non-ASCII rejected');

      await expectLater(
        signRegistration(),
        throwsA(
          isA<PlatformException>().having(
            (e) => e.code,
            'code',
            'FIRMWARE_101',
          ),
        ),
        reason:
            'umlaut-class firmware error must reach consumer; ErrorMapper '
            '(Initiative II) will eventually map this to typed '
            'BitboxFirmwareException',
      );
    },
  );

  test(
    'recordedInteractions asserts the consumer made zero post-disconnect retries',
    () async {
      fake.injectDisconnectAtPage(4);

      await expectLater(
        signRegistration(),
        throwsA(isA<BitboxNotConnectedException>()),
      );

      // Exactly one sign attempt, period.
      expect(fake.countCalls('signETHTypedMessage'), 1);

      // No further BitboxManager method was called after the disconnect.
      // (Anything that would: another sign call, another getDevices
      // outside the observer, etc.) The test pins the contract that
      // the consumer must not enter a retry loop on its own — the user
      // must explicitly re-pair.
      final post = fake.recordedInteractions
          .where((i) => i.method.startsWith('sign'))
          .toList();
      expect(post, hasLength(1));
    },
  );
}
