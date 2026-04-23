import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:uuid/uuid.dart';
import 'package:web3dart/crypto.dart';

class SecureStorage {
  static const _databaseEncryptionKey = 'drift.encryption.password';
  static const _mnemonicEncryptionKey = 'wallet.mnemonic.encryption.key';
  static const _pinHashKey = 'pin.hash';
  static const _pinSaltKey = 'pin.salt';

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
