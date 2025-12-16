import 'package:realunit_wallet/packages/storage/database.dart';
import 'package:realunit_wallet/packages/storage/wallet_storage.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

class WalletRepository {
  final AppDatabase _appDatabase;

  const WalletRepository(this._appDatabase);

  Future<int> createWallet(String name, WalletType type, String seed) =>
      _appDatabase.insertWallet(name, seed, "", type.index);

  Future<int> createViewWallet(String name, WalletType type, String address) =>
      _appDatabase.insertWallet(name, "", address, type.index);

  Future<WalletInfo?> getWalletById(int id) => _appDatabase.getWalletById(id);

  Future<void> deleteWallet(int id) => _appDatabase.deleteWallet(id);
}
