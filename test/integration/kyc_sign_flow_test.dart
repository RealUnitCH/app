// Cross-layer integration tests for the BitBox-gated KYC sign flow.
//
// These tests stitch together three layers that the registration ceremony
// touches end-to-end and that have all had production bugs in the past
// month (PR #312, #316, #318, #319):
//
//   FakeBitboxCredentials → Eip712Signer.signRegistration → SigningCancelledException
//
// They run headless (no device, no simulator), so they live under
// `test/integration/` and run as part of `flutter test`. Future scenarios
// that need the integration_test binding (full app boot, BLE/USB channels)
// will move to a top-level `integration_test/` directory.

import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/wallet/eip712_signer.dart';
import 'package:realunit_wallet/packages/wallet/exceptions/signing_cancelled_exception.dart';

import '../helper/fake_bitbox_credentials.dart';

Future<String> _signRegistration(FakeBitboxCredentials credentials) =>
    Eip712Signer.signRegistration(
      credentials: credentials,
      chainId: 1,
      type: 'HUMAN',
      email: 'fake@dfx.swiss',
      name: 'Fake User',
      phoneNumber: '+41790000000',
      birthday: '1990-01-01',
      nationality: 'CH',
      addressStreet: 'Teststrasse 1',
      addressPostalCode: '8000',
      addressCity: 'Zurich',
      addressCountry: 'CH',
      swissTaxResidence: true,
      registrationDate: '2026-05-13',
    );

void main() {
  group('KYC sign flow — FakeBitboxCredentials × Eip712Signer', () {
    test(
      'happy path: fake produces a sig that passes the empty-signature guard',
      () async {
        final fake = FakeBitboxCredentials(signDelay: Duration.zero);

        final sig = await _signRegistration(fake);

        expect(sig, startsWith('0x'));
        expect(sig.length, 132);
        expect(fake.signCallCount, 1);
      },
    );

    test(
      'cancel mid-sign: fake returns "0x" → Eip712Signer throws SigningCancelledException',
      () async {
        final fake = FakeBitboxCredentials(
          behavior: FakeBitboxBehavior.cancel,
          signDelay: Duration.zero,
        );

        await expectLater(
          _signRegistration(fake),
          throwsA(isA<SigningCancelledException>()),
        );
        expect(fake.signCallCount, 1);
      },
    );

    test(
      'BLE disconnect: fake throws SigningCancelledException directly',
      () async {
        final fake = FakeBitboxCredentials(
          behavior: FakeBitboxBehavior.disconnect,
          signDelay: Duration.zero,
        );

        await expectLater(
          _signRegistration(fake),
          throwsA(isA<SigningCancelledException>()),
        );
      },
    );

    test(
      'reconnect-and-retry: a disconnected fake flipped to success completes on retry',
      () async {
        final fake = FakeBitboxCredentials(
          behavior: FakeBitboxBehavior.disconnect,
          signDelay: Duration.zero,
        );

        await expectLater(
          _signRegistration(fake),
          throwsA(isA<SigningCancelledException>()),
        );

        fake.behavior = FakeBitboxBehavior.success;
        final retrySig = await _signRegistration(fake);

        expect(retrySig, startsWith('0x'));
        expect(retrySig.length, 132);
        expect(
          fake.signCallCount,
          2,
          reason: 'one failed sign attempt and one successful retry',
        );
      },
    );
  });
}
