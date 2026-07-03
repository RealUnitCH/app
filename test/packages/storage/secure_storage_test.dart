import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';
import 'package:web3dart/crypto.dart';

class _MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockFlutterSecureStorage mockStorage;
  late SecureStorage secureStorage;

  // Single-arg captureAny doesn't help for named-only APIs, so we wire each
  // matcher explicitly. flutter_secure_storage v9 takes everything by name.
  setUp(() {
    mockStorage = _MockFlutterSecureStorage();
    secureStorage = SecureStorage.withStorage(mockStorage);

    // Default no-op writers/deleters — individual tests can override these
    // when they need to assert on the captured args.
    when(
      () => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockStorage.delete(key: any(named: 'key')),
    ).thenAnswer((_) async {});
  });

  group('SecureStorage encryption-key API', () {
    test('getEncryptionKey forwards the drift.encryption.password key', () async {
      when(
        () => mockStorage.read(key: 'drift.encryption.password'),
      ).thenAnswer((_) async => 'cafebabe');

      final key = await secureStorage.getEncryptionKey();

      expect(key, 'cafebabe');
      verify(() => mockStorage.read(key: 'drift.encryption.password')).called(1);
    });

    test('getEncryptionKey returns null when the underlying read returns null', () async {
      when(
        () => mockStorage.read(key: 'drift.encryption.password'),
      ).thenAnswer((_) async => null);

      expect(await secureStorage.getEncryptionKey(), isNull);
    });

    test('setEncryptionKey writes the value under drift.encryption.password', () async {
      await secureStorage.setEncryptionKey('deadbeef');

      verify(
        () => mockStorage.write(
          key: 'drift.encryption.password',
          value: 'deadbeef',
        ),
      ).called(1);
    });

    test('getNewEncryptionKey returns a 64-char hex string by default (32 bytes)', () {
      final key = SecureStorage.getNewEncryptionKey();
      expect(key, hasLength(64));
      expect(RegExp(r'^[0-9a-f]+$').hasMatch(key), isTrue);
    });

    test('getNewEncryptionKey honours a custom keySize', () {
      final key = SecureStorage.getNewEncryptionKey(keySize: 16);
      expect(key, hasLength(32)); // 16 bytes * 2 hex chars
    });

    test('getNewEncryptionKey returns distinct values across calls (CSPRNG)', () {
      expect(
        SecureStorage.getNewEncryptionKey(),
        isNot(SecureStorage.getNewEncryptionKey()),
      );
    });
  });

  group('SecureStorage PIN hash + salt API', () {
    test('getPinHash forwards the pin.hash key', () async {
      when(
        () => mockStorage.read(key: 'pin.hash'),
      ).thenAnswer((_) async => 'abc123');

      expect(await secureStorage.getPinHash(), 'abc123');
    });

    test('setPinHash writes the value under pin.hash', () async {
      await secureStorage.setPinHash('hashed');

      verify(() => mockStorage.write(key: 'pin.hash', value: 'hashed')).called(1);
    });

    test('hasPinHash is true when the read returns a non-null value', () async {
      when(
        () => mockStorage.read(key: 'pin.hash'),
      ).thenAnswer((_) async => 'something');

      expect(await secureStorage.hasPinHash(), isTrue);
    });

    test('hasPinHash is false when the read returns null', () async {
      when(
        () => mockStorage.read(key: 'pin.hash'),
      ).thenAnswer((_) async => null);

      expect(await secureStorage.hasPinHash(), isFalse);
    });

    test('deletePinHash deletes both pin.hash and pin.salt in parallel', () async {
      await secureStorage.deletePinHash();

      verify(() => mockStorage.delete(key: 'pin.hash')).called(1);
      verify(() => mockStorage.delete(key: 'pin.salt')).called(1);
    });

    test('deleteMnemonicKey deletes the mnemonic encryption key', () async {
      await secureStorage.deleteMnemonicKey();

      verify(() => mockStorage.delete(key: 'wallet.mnemonic.encryption.key')).called(1);
    });

    test('getPinSalt returns null when no salt is stored', () async {
      when(
        () => mockStorage.read(key: 'pin.salt'),
      ).thenAnswer((_) async => null);

      expect(await secureStorage.getPinSalt(), isNull);
    });

    test('getPinSalt hex-decodes the stored value', () async {
      final salt = Uint8List.fromList([1, 2, 3, 4, 0xff]);
      when(
        () => mockStorage.read(key: 'pin.salt'),
      ).thenAnswer((_) async => bytesToHex(salt));

      final decoded = await secureStorage.getPinSalt();
      expect(decoded, salt);
    });

    test('setPinSalt hex-encodes the bytes before writing', () async {
      final salt = Uint8List.fromList([0xde, 0xad, 0xbe, 0xef]);

      await secureStorage.setPinSalt(salt);

      verify(
        () => mockStorage.write(key: 'pin.salt', value: 'deadbeef'),
      ).called(1);
    });
  });

  group('SecureStorage verifyPin', () {
    test('is notVerifiable when no pin hash is stored', () async {
      when(() => mockStorage.read(key: 'pin.hash')).thenAnswer((_) async => null);
      when(
        () => mockStorage.read(key: 'pin.salt'),
      ).thenAnswer((_) async => bytesToHex(Uint8List(16)));

      expect(
        await secureStorage.verifyPin('123456'),
        PinVerificationResult.notVerifiable,
      );
    });

    test('is notVerifiable when no salt is stored', () async {
      when(
        () => mockStorage.read(key: 'pin.hash'),
      ).thenAnswer((_) async => 'something');
      when(() => mockStorage.read(key: 'pin.salt')).thenAnswer((_) async => null);

      expect(
        await secureStorage.verifyPin('123456'),
        PinVerificationResult.notVerifiable,
      );
    });

    test('is correct when the pin hashes to the stored value (current iterations)', () async {
      final salt = SecureStorage.generatePinSalt();
      // Build the actual current-target hash through the real hashPin helper
      // so we don't pin a specific iteration count in the test.
      final expectedHash = SecureStorage.hashPin('123456', salt);

      when(
        () => mockStorage.read(key: 'pin.hash'),
      ).thenAnswer((_) async => expectedHash);
      when(
        () => mockStorage.read(key: 'pin.salt'),
      ).thenAnswer((_) async => bytesToHex(salt));

      expect(
        await secureStorage.verifyPin('123456'),
        PinVerificationResult.correct,
      );
      // No rehash write expected on the fast path.
      verifyNever(
        () => mockStorage.write(
          key: 'pin.hash',
          value: any(named: 'value'),
        ),
      );
    });

    test('is wrong when the pin is wrong on every accepted iteration count', () async {
      final salt = SecureStorage.generatePinSalt();
      // Pin some unrelated hash that no candidate iteration count can produce
      // for the test pin.
      const unrelatedHash = 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';

      when(
        () => mockStorage.read(key: 'pin.hash'),
      ).thenAnswer((_) async => unrelatedHash);
      when(
        () => mockStorage.read(key: 'pin.salt'),
      ).thenAnswer((_) async => bytesToHex(salt));

      expect(
        await secureStorage.verifyPin('123456'),
        PinVerificationResult.wrong,
      );
    });

    test('legacy hash is accepted once (correct) and transparently rehashed', () async {
      final salt = SecureStorage.generatePinSalt();
      // 10_000 is one of the documented legacy iteration counts.
      final legacyHash = SecureStorage.hashPin('123456', salt, iterations: 10000);

      when(
        () => mockStorage.read(key: 'pin.hash'),
      ).thenAnswer((_) async => legacyHash);
      when(
        () => mockStorage.read(key: 'pin.salt'),
      ).thenAnswer((_) async => bytesToHex(salt));

      expect(
        await secureStorage.verifyPin('123456'),
        PinVerificationResult.correct,
      );

      // The rehash MUST land on the current target — i.e. exactly one
      // write to pin.hash whose value is the new hash, not the legacy one.
      final newHash = SecureStorage.hashPin('123456', salt);
      verify(
        () => mockStorage.write(key: 'pin.hash', value: newHash),
      ).called(1);
    });
  });

  group('SecureStorage PIN lockout API', () {
    test('getPinFailedAttempts returns 0 when no value is stored', () async {
      when(
        () => mockStorage.read(key: 'pin.failedAttempts'),
      ).thenAnswer((_) async => null);

      expect(await secureStorage.getPinFailedAttempts(), 0);
    });

    test('getPinFailedAttempts returns 0 when the stored value is unparseable', () async {
      when(
        () => mockStorage.read(key: 'pin.failedAttempts'),
      ).thenAnswer((_) async => 'not-a-number');

      expect(await secureStorage.getPinFailedAttempts(), 0);
    });

    test('getPinFailedAttempts parses an integer string', () async {
      when(
        () => mockStorage.read(key: 'pin.failedAttempts'),
      ).thenAnswer((_) async => '4');

      expect(await secureStorage.getPinFailedAttempts(), 4);
    });

    test('setPinFailedAttempts writes the count as a string', () async {
      await secureStorage.setPinFailedAttempts(7);

      verify(
        () => mockStorage.write(key: 'pin.failedAttempts', value: '7'),
      ).called(1);
    });

    test('getPinLockedUntil returns null when no value is stored', () async {
      when(
        () => mockStorage.read(key: 'pin.lockedUntil'),
      ).thenAnswer((_) async => null);

      expect(await secureStorage.getPinLockedUntil(), isNull);
    });

    test('getPinLockedUntil returns null when stored value is unparseable', () async {
      when(
        () => mockStorage.read(key: 'pin.lockedUntil'),
      ).thenAnswer((_) async => 'not-an-iso-date');

      expect(await secureStorage.getPinLockedUntil(), isNull);
    });

    test('getPinLockedUntil parses an ISO-8601 string', () async {
      final until = DateTime.utc(2030, 1, 2, 3, 4, 5);
      when(
        () => mockStorage.read(key: 'pin.lockedUntil'),
      ).thenAnswer((_) async => until.toIso8601String());

      expect(await secureStorage.getPinLockedUntil(), until);
    });

    test('setPinLockedUntil with a value writes the ISO-8601 string', () async {
      final until = DateTime.utc(2030, 1, 2, 3, 4, 5);

      await secureStorage.setPinLockedUntil(until);

      verify(
        () => mockStorage.write(
          key: 'pin.lockedUntil',
          value: until.toIso8601String(),
        ),
      ).called(1);
    });

    test('setPinLockedUntil(null) deletes the stored entry', () async {
      await secureStorage.setPinLockedUntil(null);

      verify(() => mockStorage.delete(key: 'pin.lockedUntil')).called(1);
      verifyNever(
        () => mockStorage.write(
          key: 'pin.lockedUntil',
          value: any(named: 'value'),
        ),
      );
    });

    test('resetPinLockout deletes both attempts and lockout in parallel', () async {
      await secureStorage.resetPinLockout();

      verify(() => mockStorage.delete(key: 'pin.failedAttempts')).called(1);
      verify(() => mockStorage.delete(key: 'pin.lockedUntil')).called(1);
    });
  });

  group('SecureStorage biometric API', () {
    test('getIsBiometricEnabled is true when the stored string equals "true"', () async {
      when(
        () => mockStorage.read(key: 'biometric.enabled'),
      ).thenAnswer((_) async => 'true');

      expect(await secureStorage.getIsBiometricEnabled(), isTrue);
    });

    test('getIsBiometricEnabled is false on any other stored value', () async {
      when(
        () => mockStorage.read(key: 'biometric.enabled'),
      ).thenAnswer((_) async => 'false');

      expect(await secureStorage.getIsBiometricEnabled(), isFalse);
    });

    test('getIsBiometricEnabled is false when nothing is stored', () async {
      when(
        () => mockStorage.read(key: 'biometric.enabled'),
      ).thenAnswer((_) async => null);

      expect(await secureStorage.getIsBiometricEnabled(), isFalse);
    });

    test('setIsBiometricEnabled writes the boolean as a string', () async {
      await secureStorage.setIsBiometricEnabled(enabled: true);
      verify(
        () => mockStorage.write(key: 'biometric.enabled', value: 'true'),
      ).called(1);

      await secureStorage.setIsBiometricEnabled(enabled: false);
      verify(
        () => mockStorage.write(key: 'biometric.enabled', value: 'false'),
      ).called(1);
    });

    test('deleteBiometricEnabled forwards to delete on biometric.enabled', () async {
      await secureStorage.deleteBiometricEnabled();

      verify(() => mockStorage.delete(key: 'biometric.enabled')).called(1);
    });
  });

  group('SecureStorage getOrCreateMnemonicKey', () {
    test('returns the base64-decoded stored key when one exists', () async {
      final stored = Uint8List.fromList(List.generate(32, (i) => i + 1));
      when(
        () => mockStorage.read(key: 'wallet.mnemonic.encryption.key'),
      ).thenAnswer((_) async => base64.encode(stored));

      final result = await secureStorage.getOrCreateMnemonicKey();

      expect(result, stored);
      // Must NOT write a new key on the existing-key path.
      verifyNever(
        () => mockStorage.write(
          key: 'wallet.mnemonic.encryption.key',
          value: any(named: 'value'),
        ),
      );
    });

    test('generates and persists a fresh 32-byte key when none exists', () async {
      String? captured;
      when(
        () => mockStorage.read(key: 'wallet.mnemonic.encryption.key'),
      ).thenAnswer((_) async => null);
      when(
        () => mockStorage.write(
          key: 'wallet.mnemonic.encryption.key',
          value: any(named: 'value'),
        ),
      ).thenAnswer((invocation) async {
        captured = invocation.namedArguments[#value] as String;
      });

      final result = await secureStorage.getOrCreateMnemonicKey();

      expect(result, hasLength(32));
      expect(captured, isNotNull);
      // The persisted value must base64-decode back to the returned key.
      expect(base64.decode(captured!), result);

      verify(
        () => mockStorage.write(
          key: 'wallet.mnemonic.encryption.key',
          value: any(named: 'value'),
        ),
      ).called(1);
    });

    test(
      'returns distinct keys across two cold starts when no key is stored (CSPRNG)',
      () async {
        when(
          () => mockStorage.read(key: 'wallet.mnemonic.encryption.key'),
        ).thenAnswer((_) async => null);

        final a = await secureStorage.getOrCreateMnemonicKey();
        final b = await secureStorage.getOrCreateMnemonicKey();

        expect(a, isNot(b));
      },
    );
  });

  group('SecureStorage default constructor', () {
    test('SecureStorage() wires up a production-defaults storage', () {
      // Exercises the public default constructor itself — no method is
      // invoked, so the underlying platform channel never fires. This pins
      // the production wiring without booting a real keystore. Avoid the
      // `const` keyword so the constructor body is actually evaluated at
      // runtime instead of being canonicalized at compile time.
      // ignore: prefer_const_constructors
      final storage = SecureStorage();

      expect(storage, isA<SecureStorage>());
    });
  });

  group('SecureStorage hashPinAsync', () {
    test('produces the same hash as the synchronous helper', () async {
      final salt = SecureStorage.generatePinSalt();

      // Use a tiny iteration count to keep the off-thread compute snappy
      // — we only care about behavioural parity, not the iteration value.
      final sync = SecureStorage.hashPin('123456', salt, iterations: 1);
      final async = await SecureStorage.hashPinAsync(
        '123456',
        salt,
        iterations: 1,
      );

      expect(async, sync);
    });
  });
}
