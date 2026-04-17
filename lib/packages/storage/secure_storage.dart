import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:web3dart/crypto.dart';

class SecureStorage {
  static const _encryptionKey = 'drift.encryption.password';
  static const _pinHashKey = 'pin.hash';
  static const _pinSaltKey = 'pin.salt';

  final FlutterSecureStorage _secureStorage;

  const SecureStorage() : _secureStorage = const FlutterSecureStorage();

  // Database

  static String getNewEncryptionKey({int keySize = 32}) {
    final keyBytes = _secureRandomBytes(keySize);
    return bytesToHex(keyBytes);
  }

  Future<String?> getEncryptionKey() => _secureStorage.read(key: _encryptionKey);

  Future<void> setEncryptionKey(String key) =>
      _secureStorage.write(key: _encryptionKey, value: key);

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

  Future<void> deletePinHash() => Future.wait([
    _secureStorage.delete(key: _pinHashKey),
    _secureStorage.delete(key: _pinSaltKey),
  ]);

  static Uint8List _secureRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
  }
}
