import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:web3dart/crypto.dart';

class SecureStorage {
  static const _databaseEncryptionKey = 'drift.encryption.password';
  static const _mnemonicEncryptionKey = 'wallet.mnemonic.encryption.key';
  static const _pinHashKey = 'pin.hash';
  static const _pinSaltKey = 'pin.salt';
  static const _biometricEnabledKey = 'biometric.enabled';
  static const _pinFailedAttemptsKey = 'pin.failedAttempts';
  static const _pinLockedUntilKey = 'pin.lockedUntil';

  final FlutterSecureStorage _secureStorage;

  const SecureStorage() : _secureStorage = const FlutterSecureStorage();

  /// Test-only constructor that injects a [FlutterSecureStorage] (typically a
  /// mock or the platform-interface-backed `TestFlutterSecureStoragePlatform`).
  /// Lets unit tests exercise every instance method without booting a real
  /// platform channel — the production code path stays untouched.
  @visibleForTesting
  const SecureStorage.withStorage(this._secureStorage);

  // Database

  static String getNewEncryptionKey({int keySize = 32}) {
    final keyBytes = _secureRandomBytes(keySize);
    return bytesToHex(keyBytes);
  }

  Future<String?> getEncryptionKey() => _secureStorage.read(key: _databaseEncryptionKey);

  Future<void> setEncryptionKey(String key) =>
      _secureStorage.write(key: _databaseEncryptionKey, value: key);

  // Pin

  static Uint8List generatePinSalt() {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(16, (_) => random.nextInt(256)));
  }

  // PIN-hash iteration count, picked for sub-second verification on mid-range
  // phones. The PIN hash + salt live in [FlutterSecureStorage] (Android Keystore
  // / iOS Keychain), so an offline brute-force first requires breaking that
  // hardware-backed boundary. Online brute-force against the app UI is bounded
  // by the lockout cascade in `verify_pin_cubit.dart`. The stronger guarantee
  // for the actual private key comes from the OS-keystore-managed mnemonic
  // encryption key — not from this hash. 250k roughly doubles the offline
  // brute-force cost vs. 100k while staying perceptibly sub-second on the
  // median target phone. Earlier 100k / 600k / 10k hashes are still accepted
  // and transparently rehashed to [_pinHashIterations].
  static const _pinHashIterations = 250000;
  static const _legacyIterationCandidates = <int>[600000, 100000, 10000];

  static String hashPin(String pin, Uint8List salt, {int iterations = _pinHashIterations}) {
    final derivator = KeyDerivator('SHA-256/HMAC/PBKDF2');
    final params = Pbkdf2Parameters(salt, iterations, 32);
    derivator.init(params);
    return bytesToHex(derivator.process(utf8.encode(pin)));
  }

  /// Off-main-thread variant of [hashPin]. Even at the reduced iteration count
  /// PBKDF2 dominates the visible unlock latency, so any caller reachable from
  /// the UI should await this instead of running it synchronously.
  static Future<String> hashPinAsync(
    String pin,
    Uint8List salt, {
    int iterations = _pinHashIterations,
  }) => compute(
    _hashPinIsolate,
    (pin: pin, salt: salt, iterations: iterations),
  );

  Future<String?> getPinHash() => _secureStorage.read(key: _pinHashKey);

  Future<void> setPinHash(String hash) => _secureStorage.write(key: _pinHashKey, value: hash);

  Future<bool> hasPinHash() async => await _secureStorage.read(key: _pinHashKey) != null;

  Future<void> deletePinHash() => Future.wait([
    _secureStorage.delete(key: _pinHashKey),
    _secureStorage.delete(key: _pinSaltKey),
  ]);

  Future<Uint8List?> getPinSalt() async {
    final hex = await _secureStorage.read(key: _pinSaltKey);
    if (hex == null) return null;
    return hexToBytes(hex);
  }

  Future<void> setPinSalt(Uint8List salt) =>
      _secureStorage.write(key: _pinSaltKey, value: bytesToHex(salt));

  Future<bool> verifyPin(String pin) async {
    final hash = await getPinHash();
    final salt = await getPinSalt();
    if (hash == null || salt == null) return false;

    if (await hashPinAsync(pin, salt) == hash) return true;

    // Transparent rehash: any earlier iteration count we ever shipped is still
    // accepted exactly once, then upgraded to the current target so subsequent
    // unlocks pay the fast path.
    for (final legacy in _legacyIterationCandidates) {
      if (await hashPinAsync(pin, salt, iterations: legacy) == hash) {
        final newHash = await hashPinAsync(pin, salt);
        await setPinHash(newHash);
        return true;
      }
    }

    return false;
  }

  // Pin lockout

  Future<int> getPinFailedAttempts() async {
    final value = await _secureStorage.read(key: _pinFailedAttemptsKey);
    return int.tryParse(value ?? '') ?? 0;
  }

  Future<void> setPinFailedAttempts(int count) =>
      _secureStorage.write(key: _pinFailedAttemptsKey, value: count.toString());

  Future<DateTime?> getPinLockedUntil() async {
    final value = await _secureStorage.read(key: _pinLockedUntilKey);
    return value != null ? DateTime.tryParse(value) : null;
  }

  Future<void> setPinLockedUntil(DateTime? until) => until != null
      ? _secureStorage.write(key: _pinLockedUntilKey, value: until.toIso8601String())
      : _secureStorage.delete(key: _pinLockedUntilKey);

  Future<void> resetPinLockout() => Future.wait([
    _secureStorage.delete(key: _pinFailedAttemptsKey),
    _secureStorage.delete(key: _pinLockedUntilKey),
  ]);

  // Biometric

  Future<bool> getIsBiometricEnabled() async =>
      await _secureStorage.read(key: _biometricEnabledKey) == 'true';

  Future<void> setIsBiometricEnabled({required bool enabled}) =>
      _secureStorage.write(key: _biometricEnabledKey, value: enabled.toString());

  Future<void> deleteBiometricEnabled() => _secureStorage.delete(key: _biometricEnabledKey);

  // Mnemonic

  Future<Uint8List> getOrCreateMnemonicKey() async {
    final existing = await _secureStorage.read(key: _mnemonicEncryptionKey);
    if (existing != null) return base64.decode(existing);
    final key = _secureRandomBytes(32);
    await _secureStorage.write(key: _mnemonicEncryptionKey, value: base64.encode(key));
    return key;
  }

  static String encryptSeed(Uint8List key, String plaintext) {
    final iv = _secureRandomBytes(12);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
    final ciphertext = cipher.process(Uint8List.fromList(utf8.encode(plaintext)));
    return '${base64.encode(iv)}:${base64.encode(ciphertext)}';
  }

  static String decryptSeed(Uint8List key, String encoded) {
    final colonIndex = encoded.indexOf(':');
    final iv = base64.decode(encoded.substring(0, colonIndex));
    final ciphertext = base64.decode(encoded.substring(colonIndex + 1));
    final cipher = GCMBlockCipher(AESEngine())
      ..init(false, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
    return utf8.decode(cipher.process(ciphertext));
  }

  static Uint8List _secureRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
  }
}

String _hashPinIsolate(({String pin, Uint8List salt, int iterations}) args) =>
    SecureStorage.hashPin(args.pin, args.salt, iterations: args.iterations);
