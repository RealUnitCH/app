// Tier-0 tests for the BL-045 PIN-iteration policy + BL-050
// flutter_secure_storage options. The verifyPin tests exercise the
// static hashPin path directly (the instance-level FlutterSecureStorage
// requires platform-channel scaffolding that isn't worth threading
// through a unit test); the options test snapshots the surfaced
// constants so a refactor that drops `first_unlock_this_device` or
// `encryptedSharedPreferences` fails the test.

import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';

void main() {
  group('PIN-iteration policy (BL-045)', () {
    test('the current iteration count is OWASP-2025 PBKDF2-HMAC-SHA256 (600k)', () {
      expect(SecureStorage.currentIterations, 600000,
          reason: 'BL-045: the production iteration count must match OWASP 2025 — '
              'a refactor that drops this back to 250k must fail loudly');
    });

    test('the legacy acceptance set contains 250k and 100k', () {
      expect(SecureStorage.legacyIterationCandidates, containsAll([250000, 100000]),
          reason: 'transparent rehash must cover the two iteration counts we '
              'ever shipped to production before the BL-045 bump');
    });

    test('10k is explicitly REJECTED, not accepted as legacy', () {
      expect(SecureStorage.legacyIterationCandidates, isNot(contains(10000)),
          reason: 'BL-045: a user landing on 10k must be force-reset, not '
              'transparently upgraded — the attacker may already have '
              'brute-forced the hash on a leaked snapshot');
      expect(SecureStorage.rejectedIterationCandidates, contains(10000));
    });

    test('600k hashing produces a distinct hash from 250k and 10k for the '
        'same pin+salt', () {
      // Pin the migration trigger: if all three iteration counts
      // collided on the same hash output, the verify path could not
      // distinguish them and the rehash semantics would be vacuous.
      final salt = SecureStorage.generatePinSalt();

      final h600k = SecureStorage.hashPin('123456', salt, iterations: 600000);
      final h250k = SecureStorage.hashPin('123456', salt, iterations: 250000);
      final h10k = SecureStorage.hashPin('123456', salt, iterations: 10000);

      expect(h600k, isNot(h250k),
          reason: '600k must produce a different hash from 250k for the '
              'same input — otherwise the legacy detection branch is dead code');
      expect(h600k, isNot(h10k));
      expect(h250k, isNot(h10k));
    });

    test('600k hash is deterministic for the same pin+salt', () {
      final salt = SecureStorage.generatePinSalt();

      final a = SecureStorage.hashPin('pin', salt, iterations: 600000);
      final b = SecureStorage.hashPin('pin', salt, iterations: 600000);

      expect(a, b,
          reason: 'PBKDF2 is deterministic — a regression here would mean a '
              'second unlock with the same PIN no longer matches the stored hash');
    });
  });

  group('flutter_secure_storage options snapshot (BL-050)', () {
    test('iosOptions pin first_unlock_this_device', () {
      // Snapshot test: a refactor that drops this constraint flips
      // the accessibility back to the default (unlocked + iCloud
      // restore-restorable), which would allow a Keychain entry to
      // be carried to a new device via backup. Locking it here makes
      // the change a deliberate review point.
      //
      // The private fields are not directly observable; toMap() is
      // the public hook the platform channel uses, so we assert
      // against the serialised form. The deprecated `describeEnum`
      // produces the enum's name without the type prefix.
      final serialised = SecureStorage.iosOptions.toMap();
      expect(serialised['accessibility'], 'first_unlock_this_device',
          reason: 'BL-050: iOS Keychain entries must NOT be restorable '
              'to a different device via iCloud backup');
    });

    test('androidOptions pin encryptedSharedPreferences == true', () {
      // The default on older Android versions writes plaintext to
      // SharedPreferences. The explicit opt-in makes the
      // encryption-at-rest constraint a regression test rather than
      // a hidden default that could flip.
      final serialised = SecureStorage.androidOptions.toMap();
      expect(serialised['encryptedSharedPreferences'], 'true',
          reason: 'BL-050: Android secure-storage must go through '
              'EncryptedSharedPreferences (AES-256-GCM bound to the Keystore)');
    });
  });
}
