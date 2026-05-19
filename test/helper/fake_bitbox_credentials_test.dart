import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_credentials.dart';
import 'package:realunit_wallet/packages/wallet/exceptions/signing_cancelled_exception.dart';

import 'fake_bitbox_credentials.dart';

const _typedData =
    '{"types":{"EIP712Domain":[{"name":"name","type":"string"}],'
    '"T":[{"name":"x","type":"string"}]},'
    '"primaryType":"T","domain":{"name":"T"},"message":{"x":"y"}}';

void main() {
  group('$FakeBitboxCredentials', () {
    test('is recognised as a BitboxCredentials (type guard preserved)', () {
      final fake = FakeBitboxCredentials();

      expect(fake, isA<BitboxCredentials>());
    });

    test('derives a stable address from the embedded test private key', () {
      final a = FakeBitboxCredentials();
      final b = FakeBitboxCredentials();

      expect(a.address, equals(b.address));
      // EIP-55 checksummed form — sanity that we are wired to web3dart.
      expect(a.address.hexEip55, startsWith('0x'));
    });

    test('accepts an explicit address override', () {
      const explicit = '0x1111111111111111111111111111111111111111';
      final fake = FakeBitboxCredentials(address: explicit);

      expect(fake.address.hex.toLowerCase(), explicit.toLowerCase());
    });

    group('signTypedDataV4', () {
      test('success: returns a deterministic valid signature', () async {
        final fake = FakeBitboxCredentials(signDelay: Duration.zero);

        final sig = await fake.signTypedDataV4(1, _typedData);

        expect(sig, startsWith('0x'));
        expect(sig.length, 132); // '0x' + 130 hex chars = 65 bytes
        expect(fake.signCallCount, 1);
      });

      test("cancel: returns '0x' (matches the iOS bridge's cancel signal)", () async {
        final fake = FakeBitboxCredentials(
          behavior: FakeBitboxBehavior.cancel,
          signDelay: Duration.zero,
        );

        final sig = await fake.signTypedDataV4(1, _typedData);

        expect(sig, '0x');
      });

      test('disconnect: throws SigningCancelledException', () async {
        final fake = FakeBitboxCredentials(
          behavior: FakeBitboxBehavior.disconnect,
          signDelay: Duration.zero,
        );

        expect(
          () => fake.signTypedDataV4(1, _typedData),
          throwsA(isA<SigningCancelledException>()),
        );
      });

      test('disconnect: reports isConnected == false', () {
        final fake = FakeBitboxCredentials(behavior: FakeBitboxBehavior.disconnect);

        expect(fake.isConnected, isFalse);
      });

      test('non-disconnect behaviours report isConnected == true', () {
        for (final mode in const [
          FakeBitboxBehavior.success,
          FakeBitboxBehavior.cancel,
          FakeBitboxBehavior.timeout,
          FakeBitboxBehavior.malformed,
        ]) {
          final fake = FakeBitboxCredentials(behavior: mode);
          expect(fake.isConnected, isTrue, reason: 'mode $mode');
        }
      });

      test('timeout: never resolves (caller must impose its own timeout)', () async {
        final fake = FakeBitboxCredentials(
          behavior: FakeBitboxBehavior.timeout,
          signDelay: Duration.zero,
        );

        await expectLater(
          fake.signTypedDataV4(1, _typedData).timeout(const Duration(milliseconds: 50)),
          throwsA(isA<TimeoutException>()),
        );
      });

      test('malformed: returns a non-hex string (frame-desync simulation)', () async {
        final fake = FakeBitboxCredentials(
          behavior: FakeBitboxBehavior.malformed,
          signDelay: Duration.zero,
        );

        final sig = await fake.signTypedDataV4(1, _typedData);

        expect(sig, isNot(matches(RegExp(r'^0x[0-9a-f]+$'))));
      });

      test('honours signDelay before resolving', () async {
        final fake = FakeBitboxCredentials(
          signDelay: const Duration(milliseconds: 100),
        );

        final sw = Stopwatch()..start();
        await fake.signTypedDataV4(1, _typedData);
        sw.stop();

        expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(80));
      });

      test('behaviour flip after construction simulates reconnect', () async {
        final fake = FakeBitboxCredentials(
          behavior: FakeBitboxBehavior.disconnect,
          signDelay: Duration.zero,
        );

        await expectLater(
          fake.signTypedDataV4(1, _typedData),
          throwsA(isA<SigningCancelledException>()),
        );

        fake.behavior = FakeBitboxBehavior.success;
        final retrySig = await fake.signTypedDataV4(1, _typedData);

        expect(retrySig, startsWith('0x'));
        expect(retrySig.length, 132);
      });
    });

    group('signPersonalMessage', () {
      test('success: returns a 65-byte signature', () async {
        final fake = FakeBitboxCredentials(signDelay: Duration.zero);

        final sig = await fake.signPersonalMessage(Uint8List.fromList([1, 2, 3]));

        expect(sig.length, 65);
      });

      test('cancel: returns empty bytes', () async {
        final fake = FakeBitboxCredentials(
          behavior: FakeBitboxBehavior.cancel,
          signDelay: Duration.zero,
        );

        final sig = await fake.signPersonalMessage(Uint8List.fromList([1, 2, 3]));

        expect(sig, isEmpty);
      });

      test('disconnect: throws SigningCancelledException', () async {
        final fake = FakeBitboxCredentials(
          behavior: FakeBitboxBehavior.disconnect,
          signDelay: Duration.zero,
        );

        expect(
          () => fake.signPersonalMessage(Uint8List.fromList([1, 2, 3])),
          throwsA(isA<SigningCancelledException>()),
        );
      });
    });
  });
}
