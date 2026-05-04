import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:biometric_storage/biometric_storage.dart';
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

  Uint8List? _cachedMnemonicKey;

  SecureStorage() : _secureStorage = const FlutterSecureStorage();

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

  static String hashPin(String pin, Uint8List salt) {
    final derivator = KeyDerivator('SHA-256/HMAC/PBKDF2');
    final params = Pbkdf2Parameters(salt, 10000, 32);
    derivator.init(params);
    return bytesToHex(derivator.process(utf8.encode(pin)));
  }

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
    return hashPin(pin, salt) == hash;
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

  // Mnemonic — biometric-gated via hardware keystore

  static const _biometricMnemonicKey = 'wallet.mnemonic.key.biometric';

  /// Pre-authenticate via biometric and cache the mnemonic key.
  /// Returns true if successful — subsequent getOrCreateMnemonicKey() will
  /// use the cached key without showing another biometric prompt.
  Future<bool> tryBiometricUnlock() async {
    final biometricAvailable =
        await BiometricStorage().canAuthenticate() == CanAuthenticateResponse.success;
    if (!biometricAvailable) return false;

    // Skip if migration is pending (legacy key exists) — migration needs its own prompt
    final legacyKey = await _secureStorage.read(key: _mnemonicEncryptionKey);
    if (legacyKey != null) return false;

    try {
      final storage = await _getBiometricStorage();
      final existing = await storage.read();
      if (existing != null) {
        _cachedMnemonicKey = base64.decode(existing);
        return true;
      }
    } on AuthException {
      return false;
    }
    return false;
  }

  Future<Uint8List> getOrCreateMnemonicKey() async {
    final cached = _cachedMnemonicKey;
    if (cached != null) {
      _cachedMnemonicKey = null;
      return cached;
    }

    final biometricAvailable =
        await BiometricStorage().canAuthenticate() == CanAuthenticateResponse.success;

    if (biometricAvailable) {
      return _getOrCreateBiometricMnemonicKey();
    }

    return _getOrCreateLegacyMnemonicKey();
  }

  Future<BiometricStorageFile> _getBiometricStorage() => BiometricStorage().getStorage(
    _biometricMnemonicKey,
    options: StorageFileInitOptions(
      authenticationRequired: true,
      androidBiometricOnly: false,
    ),
    promptInfo: const PromptInfo(
      androidPromptInfo: AndroidPromptInfo(
        title: 'Unlock Wallet',
        subtitle: 'Authenticate to access your wallet',
        negativeButton: 'Cancel',
      ),
      iosPromptInfo: IosPromptInfo(
        accessTitle: 'Unlock to access your wallet',
      ),
    ),
  );

  Future<Uint8List> _getOrCreateBiometricMnemonicKey() async {
    // Check legacy storage first (no biometric prompt needed)
    final legacyKey = await _secureStorage.read(key: _mnemonicEncryptionKey);
    if (legacyKey != null) {
      // Migrate: write to biometric storage (triggers prompt), then delete legacy
      final storage = await _getBiometricStorage();
      await storage.write(legacyKey);
      await _secureStorage.delete(key: _mnemonicEncryptionKey);
      return base64.decode(legacyKey);
    }

    // Read from biometric storage (triggers prompt if value exists)
    final storage = await _getBiometricStorage();
    final existing = await storage.read();
    if (existing != null) return base64.decode(existing);

    // Generate new key and store with biometric protection
    final key = _secureRandomBytes(32);
    await storage.write(base64.encode(key));
    return key;
  }

  Future<Uint8List> _getOrCreateLegacyMnemonicKey() async {
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
