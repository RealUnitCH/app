import 'package:realunit_wallet/packages/storage/database.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';
import 'package:realunit_wallet/packages/storage/wallet_storage.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

class WalletRepository {
  final AppDatabase _appDatabase;
  final SecureStorage _secureStorage;

  const WalletRepository(this._appDatabase, this._secureStorage);

  Future<int> createWallet(String name, WalletType type, String seed) async {
    final encryptedSeed = await _encryptSeed(seed);
    return _appDatabase.insertWallet(name, encryptedSeed, '', type.index);
  }

  Future<int> createViewWallet(String name, WalletType type, String address) =>
      _appDatabase.insertWallet(name, '', address, type.index);

  Future<WalletInfo?> getWalletById(int id) async {
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
