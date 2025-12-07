import 'package:drift/drift.dart';
import 'package:realunit_wallet/packages/storage/database.dart';

extension WalletStorage on AppDatabase {
  Future<int> insertWallet(
          String name, String seed, String address, int walletType) =>
      into(walletInfos).insert(WalletInfosCompanion.insert(
          name: name, seed: seed, address: address, type: walletType));

  Future<WalletInfo?> getWalletById(int id) =>
      (select(walletInfos)..where((row) => row.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertWalletAccount(
          int walletId, String name, int accountIndex) =>
      into(walletAccountInfos).insert(WalletAccountInfosCompanion.insert(
          name: name, accountIndex: accountIndex, wallet: walletId));

  Future<List<WalletAccountInfo>> getWalletAccounts(int walletId) =>
      (select(walletAccountInfos)..where((row) => row.wallet.equals(walletId)))
          .get();

  Future<int> deleteWallet(int walletId) =>
      (delete(walletAccountInfos)..where((row) => row.wallet.equals(walletId)))
          .go();

  Future<bool> get hasWallet =>
      select(walletInfos).get().then((result) => result.isNotEmpty);
}

@DataClassName("WalletInfo")
class WalletInfos extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  TextColumn get seed => text()();

  TextColumn get address => text()();

  IntColumn get type => integer()();
}

@DataClassName("WalletAccountInfo")
class WalletAccountInfos extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  IntColumn get accountIndex => integer()();

  IntColumn get wallet => integer().references(WalletInfos, #id)();
}
