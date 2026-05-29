// Tier-0 tests for the BL-045 PIN-iteration policy + BL-050
// flutter_secure_storage options. The verifyPin tests exercise the
// static hashPin path directly (the instance-level FlutterSecureStorage
// requires platform-channel scaffolding that isn't worth threading
// through a unit test); the options test snapshots the surfaced
// constants so a refactor that drops `first_unlock_this_device` or
// `encryptedSharedPreferences` fails the test.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';

Map<String, String> _installSecureStorageFixture() {
  final data = <String, String>{};
  FlutterSecureStorage.setMockInitialValues(data);
  return data;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PIN-iteration policy (BL-045)', () {
    test('the current iteration count is OWASP-2025 PBKDF2-HMAC-SHA256 (600k)', () {
      expect(
        SecureStorage.currentIterations,
        600000,
        reason:
            'BL-045: the production iteration count must match OWASP 2025 — '
            'a refactor that drops this back to 250k must fail loudly',
      );
    });

    test('the legacy acceptance set contains 250k and 100k', () {
      expect(
        SecureStorage.legacyIterationCandidates,
        containsAll([250000, 100000]),
        reason:
            'transparent rehash must cover the two iteration counts we '
            'ever shipped to production before the BL-045 bump',
      );
    });

    test('10k is explicitly REJECTED, not accepted as legacy', () {
      expect(
        SecureStorage.legacyIterationCandidates,
        isNot(contains(10000)),
        reason:
            'BL-045: a user landing on 10k must be force-reset, not '
            'transparently upgraded — the attacker may already have '
            'brute-forced the hash on a leaked snapshot',
      );
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

      expect(
        h600k,
        isNot(h250k),
        reason:
            '600k must produce a different hash from 250k for the '
            'same input — otherwise the legacy detection branch is dead code',
      );
      expect(h600k, isNot(h10k));
      expect(h250k, isNot(h10k));
    });

    test('600k hash is deterministic for the same pin+salt', () {
      final salt = SecureStorage.generatePinSalt();

      final a = SecureStorage.hashPin('pin', salt, iterations: 600000);
      final b = SecureStorage.hashPin('pin', salt, iterations: 600000);

      expect(
        a,
        b,
        reason:
            'PBKDF2 is deterministic — a regression here would mean a '
            'second unlock with the same PIN no longer matches the stored hash',
      );
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
      expect(
        serialised['accessibility'],
        'first_unlock_this_device',
        reason:
            'BL-050: iOS Keychain entries must NOT be restorable '
            'to a different device via iCloud backup',
      );
    });

    test('androidOptions pin encryptedSharedPreferences == true', () {
      // The default on older Android versions writes plaintext to
      // SharedPreferences. The explicit opt-in makes the
      // encryption-at-rest constraint a regression test rather than
      // a hidden default that could flip.
      final serialised = SecureStorage.androidOptions.toMap();
      expect(
        serialised['encryptedSharedPreferences'],
        'true',
        reason:
            'BL-050: Android secure-storage must go through '
            'EncryptedSharedPreferences (AES-256-GCM bound to the Keystore)',
      );
    });
  });

  group('SecureStorage instance API', () {
    late Map<String, String> data;
    late SecureStorage storage;

    setUp(() {
      data = _installSecureStorageFixture();
      final storageFactory = SecureStorage.withStorage;
      storage = storageFactory(const FlutterSecureStorage());
    });

    test('default constructor is instantiable with hardened platform options', () {
      final storageFactory = SecureStorage.new;
      expect(storageFactory(), isA<SecureStorage>());
    });

    test('database encryption key round-trips through secure storage', () async {
      expect(await storage.getEncryptionKey(), isNull);

      await storage.setEncryptionKey('db-key');

      expect(await storage.getEncryptionKey(), 'db-key');
    });

    test('getNewEncryptionKey returns a 32-byte hex key by default', () {
      final key = SecureStorage.getNewEncryptionKey();

      expect(key, hasLength(64));
      expect(RegExp(r'^[0-9a-f]+$').hasMatch(key), isTrue);
    });

    test('PIN hash and salt round-trip and delete together', () async {
      final salt = Uint8List.fromList(List.generate(16, (i) => i));

      expect(await storage.hasPinHash(), isFalse);
      expect(await storage.getPinSalt(), isNull);

      await storage.setPinHash('hash');
      await storage.setPinSalt(salt);

      expect(await storage.hasPinHash(), isTrue);
      expect(await storage.getPinHash(), 'hash');
      expect(await storage.getPinSalt(), salt);

      await storage.deletePinHash();

      expect(await storage.hasPinHash(), isFalse);
      expect(await storage.getPinSalt(), isNull);
    });

    test('verifyPin rejects missing hash or salt', () async {
      expect(await storage.verifyPin('123456'), isFalse);

      await storage.setPinHash('hash-without-salt');

      expect(await storage.verifyPin('123456'), isFalse);
    });

    test('verifyPin accepts current hash without rewriting it', () async {
      final salt = Uint8List.fromList(List.generate(16, (i) => 0x10 + i));
      final hash = await SecureStorage.hashPinAsync('123456', salt);

      await storage.setPinSalt(salt);
      await storage.setPinHash(hash);

      expect(await storage.verifyPin('123456'), isTrue);
      expect(await storage.getPinHash(), hash);
    });

    test('verifyPin transparently rehashes accepted legacy hashes', () async {
      final salt = Uint8List.fromList(List.generate(16, (i) => 0x20 + i));
      final legacyHash = await SecureStorage.hashPinAsync(
        '123456',
        salt,
        iterations: 100000,
      );

      await storage.setPinSalt(salt);
      await storage.setPinHash(legacyHash);

      expect(await storage.verifyPin('123456'), isTrue);
      final upgraded = await storage.getPinHash();
      expect(upgraded, isNot(legacyHash));
      expect(upgraded, await SecureStorage.hashPinAsync('123456', salt));
    });

    test('PIN lockout counters round-trip and reset', () async {
      expect(await storage.getPinFailedAttempts(), 0);

      data['pin.failedAttempts'] = 'not-an-int';
      expect(await storage.getPinFailedAttempts(), 0);

      await storage.setPinFailedAttempts(3);
      expect(await storage.getPinFailedAttempts(), 3);

      final until = DateTime.utc(2026, 5, 29, 12, 30);
      expect(await storage.getPinLockedUntil(), isNull);

      await storage.setPinLockedUntil(until);
      expect(await storage.getPinLockedUntil(), until);

      await storage.setPinLockedUntil(null);
      expect(await storage.getPinLockedUntil(), isNull);

      await storage.setPinFailedAttempts(2);
      await storage.setPinLockedUntil(until);
      await storage.resetPinLockout();

      expect(await storage.getPinFailedAttempts(), 0);
      expect(await storage.getPinLockedUntil(), isNull);
    });

    test('biometric enabled flag round-trips and deletes', () async {
      expect(await storage.getIsBiometricEnabled(), isFalse);

      await storage.setIsBiometricEnabled(enabled: true);
      expect(await storage.getIsBiometricEnabled(), isTrue);

      await storage.deleteBiometricEnabled();
      expect(await storage.getIsBiometricEnabled(), isFalse);

      await storage.setIsBiometricEnabled(enabled: false);
      expect(await storage.getIsBiometricEnabled(), isFalse);
    });

    test('mnemonic encryption key reads existing value or creates a fresh key', () async {
      final existing = Uint8List.fromList(List.generate(32, (i) => 0xaa - i));
      data['wallet.mnemonic.encryption.key'] = base64.encode(existing);

      expect(await storage.getOrCreateMnemonicKey(), existing);

      await storage.deleteMnemonicEncryptionKey();
      expect(data.containsKey('wallet.mnemonic.encryption.key'), isFalse);

      final created = await storage.getOrCreateMnemonicKey();
      expect(created, hasLength(32));
      expect(data['wallet.mnemonic.encryption.key'], base64.encode(created));
    });

    test('biometric CryptoObject sentinel read/write is a plain secure-storage entry', () async {
      expect(await storage.readBiometricCryptoSentinel('bio.sentinel'), isNull);

      await storage.writeBiometricCryptoSentinel('bio.sentinel', 'bound');

      expect(await storage.readBiometricCryptoSentinel('bio.sentinel'), 'bound');
    });
  });
}
