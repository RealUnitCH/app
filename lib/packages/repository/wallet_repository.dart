import 'package:realunit_wallet/packages/storage/database.dart';
import 'package:realunit_wallet/packages/storage/wallet_storage.dart';

class WalletRepository {
  final AppDatabase _appDatabase;

  const WalletRepository(this._appDatabase);

  Future<int> createWallet(String name, String seed) =>
      _appDatabase.insertWallet(name, seed);

  Future<WalletInfo?> getWalletById(int id) =>
      _appDatabase.getWalletById(id);

  Future<void> deleteWallet(int id) => _appDatabase.deleteWallet(id);
}
