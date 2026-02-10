import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:uuid/uuid.dart';
import 'package:web3dart/crypto.dart';

class SecureStorage {
  static const _encryptionKey = 'drift.encryption.password';
  static const _pinHashKey = 'pin.hash';

  final FlutterSecureStorage _secureStorage;

  const SecureStorage() : _secureStorage = const FlutterSecureStorage();

  // Database

  static String getNewEncryptionKey({int keySize = 32, int iterations = 10000}) {
    final key = const Uuid().v4();
    final salt = Uint8List(9)..setRange(0, 9, utf8.encode('dEURO key'));

    final derivator = KeyDerivator('SHA-256/HMAC/PBKDF2');
    final params = Pbkdf2Parameters(salt, iterations, keySize);
    derivator.init(params);
    return bytesToHex(derivator.process(utf8.encode(key)));
  }

  Future<String?> getEncryptionKey() => _secureStorage.read(key: _encryptionKey);

  Future<void> setEncryptionKey(String key) =>
      _secureStorage.write(key: _encryptionKey, value: key);

  // Pin

  static String hashPin(String pin) {
    final salt = Uint8List(8)..setRange(0, 8, utf8.encode('PIN salt'));
    final derivator = KeyDerivator('SHA-256/HMAC/PBKDF2');
    final params = Pbkdf2Parameters(salt, 10000, 32);
    derivator.init(params);
    return bytesToHex(derivator.process(utf8.encode(pin)));
  }

  Future<String?> getPinHash() => _secureStorage.read(key: _pinHashKey);

  Future<void> setPinHash(String hash) => _secureStorage.write(key: _pinHashKey, value: hash);

  Future<void> deletePinHash() => _secureStorage.delete(key: _pinHashKey);
}
