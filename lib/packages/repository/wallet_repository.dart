import 'package:realunit_wallet/packages/storage/database.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';
import 'package:realunit_wallet/packages/storage/wallet_storage.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

class WalletRepository {
  final AppDatabase _appDatabase;
  final SecureStorage _secureStorage;

  const WalletRepository(this._appDatabase, this._secureStorage);

  Future<int> createWallet(
    String name,
    WalletType type,
    String seed,
    String address,
  ) async {
    final encryptedSeed = await _encryptSeed(seed);
    return _appDatabase.insertWallet(name, encryptedSeed, address, type.index);
  }

  Future<int> createViewWallet(String name, WalletType type, String address) =>
      _appDatabase.insertWallet(name, '', address, type.index);

  /// Returns the wallet row with the encrypted seed *still encrypted*. Use this
  /// at app startup so we don't pay the mnemonic-decrypt / BIP32-derivation
  /// cost just to render the dashboard — the cached address is enough.
  Future<WalletInfo?> getWalletInfo(int id) => _appDatabase.getWalletById(id);

  /// Returns the wallet row with the seed decrypted. Only call this when the
  /// private key is actually needed (signing a sell, revealing the seed).
  Future<WalletInfo?> getUnlockedWalletById(int id) async {
    final info = await _appDatabase.getWalletById(id);
    if (info == null) return null;
    if (info.seed.isEmpty) return info;
    return _decryptWalletInfo(info);
  }

  Future<void> deleteWallet(int id) => _appDatabase.deleteWallet(id);

  Future<WalletInfo> _decryptWalletInfo(WalletInfo info) async {
    final key = await _secureStorage.getOrCreateMnemonicKey();
    final decryptedSeed = SecureStorage.decryptSeed(key, info.seed);
    return info.copyWith(seed: decryptedSeed);
  }

  Future<String> _encryptSeed(String seed) async {
    final key = await _secureStorage.getOrCreateMnemonicKey();
    return SecureStorage.encryptSeed(key, seed);
  }
}
