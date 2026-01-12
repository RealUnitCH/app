import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:uuid/uuid.dart';
import 'package:web3dart/crypto.dart';

class SecureStorage {
  static const _encryptionKey = 'drift.encryption.password';

  final FlutterSecureStorage _secureStorage;

  const SecureStorage() : _secureStorage = const FlutterSecureStorage();

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
}
