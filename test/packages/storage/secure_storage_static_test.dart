import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';

void main() {
  group('$SecureStorage static helpers', () {
    group('generatePinSalt', () {
      test('returns a 16-byte Uint8List', () {
        final salt = SecureStorage.generatePinSalt();

        expect(salt, isA<Uint8List>());
        expect(salt, hasLength(16));
      });

      test('consecutive calls return distinct salts (CSPRNG)', () {
        final a = SecureStorage.generatePinSalt();
        final b = SecureStorage.generatePinSalt();

        // Probability of a collision on 128-bit random is negligible.
        expect(a, isNot(equals(b)));
      });

      test('every byte falls in the valid 0..255 range', () {
        final salt = SecureStorage.generatePinSalt();

        for (final b in salt) {
          expect(b, inInclusiveRange(0, 255));
        }
      });
    });

    group('hashPin', () {
      test('returns a 64-char hex string (32 bytes × 2 nibbles)', () {
        final salt = SecureStorage.generatePinSalt();

        // Pass a small iteration count so the synchronous version stays fast.
        final hash = SecureStorage.hashPin('123456', salt, iterations: 1);

        expect(hash, hasLength(64));
        expect(RegExp(r'^[0-9a-f]+$').hasMatch(hash), isTrue);
      });

      test('same pin + salt → same hash (deterministic)', () {
        final salt = SecureStorage.generatePinSalt();

        final a = SecureStorage.hashPin('123456', salt, iterations: 1);
        final b = SecureStorage.hashPin('123456', salt, iterations: 1);

        expect(a, b);
      });

      test('different pin → different hash', () {
        final salt = SecureStorage.generatePinSalt();

        final a = SecureStorage.hashPin('123456', salt, iterations: 1);
        final b = SecureStorage.hashPin('999999', salt, iterations: 1);

        expect(a, isNot(b));
      });

      test('different salt → different hash for the same pin', () {
        final saltA = SecureStorage.generatePinSalt();
        final saltB = SecureStorage.generatePinSalt();

        final a = SecureStorage.hashPin('123456', saltA, iterations: 1);
        final b = SecureStorage.hashPin('123456', saltB, iterations: 1);

        expect(a, isNot(b));
      });

      test('more iterations → different output (covers the legacy migration path)', () {
        final salt = SecureStorage.generatePinSalt();

        final a = SecureStorage.hashPin('123456', salt, iterations: 1);
        final b = SecureStorage.hashPin('123456', salt, iterations: 10);

        expect(a, isNot(b));
      });
    });

    group('encryptSeed / decryptSeed round-trip', () {
      Uint8List aesKey() {
        // 32-byte AES-256 key.
        return Uint8List.fromList(List.generate(32, (i) => i));
      }

      test('round-trips a typical 12-word mnemonic', () {
        const seed = 'test test test test test test test test test test test junk';
        final key = aesKey();

        final encoded = SecureStorage.encryptSeed(key, seed);
        final decoded = SecureStorage.decryptSeed(key, encoded);

        expect(decoded, seed);
      });

      test('round-trips an empty string', () {
        final key = aesKey();

        final encoded = SecureStorage.encryptSeed(key, '');

        expect(SecureStorage.decryptSeed(key, encoded), '');
      });

      test('round-trips unicode content', () {
        const seed = 'Schloß Größe → über 1k';
        final key = aesKey();

        final encoded = SecureStorage.encryptSeed(key, seed);

        expect(SecureStorage.decryptSeed(key, encoded), seed);
      });

      test('different IVs → different ciphertexts for the same plaintext (GCM nonce)', () {
        final key = aesKey();
        const seed = 'fixed-plaintext';

        final a = SecureStorage.encryptSeed(key, seed);
        final b = SecureStorage.encryptSeed(key, seed);

        // Each call generates a fresh 12-byte IV, so the ciphertext halves
        // (after the `iv:ciphertext` split) differ.
        expect(a, isNot(b));
      });

      test('decryptSeed with the wrong key throws a typed SeedDecryptionException', () {
        final correctKey = aesKey();
        final wrongKey = Uint8List.fromList(List.generate(32, (i) => 0xFF - i));
        final encoded = SecureStorage.encryptSeed(correctKey, 'secret');

        // GCM tag mismatch surfaces as a typed exception, not a bare
        // InvalidCipherTextException leaking out of the unlock path.
        expect(
          () => SecureStorage.decryptSeed(wrongKey, encoded),
          throwsA(isA<SeedDecryptionException>()),
        );
      });

      test('decryptSeed with a tampered ciphertext throws a typed SeedDecryptionException', () {
        final key = aesKey();
        final encoded = SecureStorage.encryptSeed(key, 'secret');
        // Flip the last character of the base64 ciphertext half so the GCM
        // authentication tag no longer verifies.
        final tampered = encoded.substring(0, encoded.length - 1) +
            (encoded.endsWith('A') ? 'B' : 'A');

        expect(
          () => SecureStorage.decryptSeed(key, tampered),
          throwsA(isA<SeedDecryptionException>()),
        );
      });

      test('output format is "<base64-iv>:<base64-ciphertext>"', () {
        final key = aesKey();

        final encoded = SecureStorage.encryptSeed(key, 'x');

        expect(encoded, contains(':'));
        final parts = encoded.split(':');
        expect(parts, hasLength(2));
        // IV is 12 bytes → base64 length 16 (with padding).
        expect(parts[0], hasLength(16));
      });

      test('decryptSeed with missing colon separator throws a typed SeedDecryptionException', () {
        final key = aesKey();

        // Previously an uncaught RangeError from `substring(0, -1)`; now a
        // controlled, catchable failure.
        expect(
          () => SecureStorage.decryptSeed(key, 'noColonHere'),
          throwsA(isA<SeedDecryptionException>()),
        );
      });

      test('decryptSeed with empty string throws a typed SeedDecryptionException', () {
        final key = aesKey();

        expect(
          () => SecureStorage.decryptSeed(key, ''),
          throwsA(isA<SeedDecryptionException>()),
        );
      });

      test('decryptSeed with a valid separator but non-base64 body throws a typed exception', () {
        final key = aesKey();

        // Colon present (clears the separator guard) but the ciphertext half
        // is not valid base64 → exercises the FormatException branch.
        expect(
          () => SecureStorage.decryptSeed(key, 'AAAAAAAAAAAAAAAA:not*valid*base64'),
          throwsA(isA<SeedDecryptionException>()),
        );
      });

      test('SeedDecryptionException carries a descriptive message and toString', () {
        SeedDecryptionException? caught;
        try {
          SecureStorage.decryptSeed(aesKey(), 'noColonHere');
        } on SeedDecryptionException catch (e) {
          caught = e;
        }

        expect(caught, isNotNull);
        expect(caught!.message, contains('IV separator'));
        expect(caught.toString(), 'SeedDecryptionException: ${caught.message}');
      });
    });
  });
}
