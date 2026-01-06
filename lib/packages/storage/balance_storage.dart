import 'package:realunit_wallet/packages/storage/database.dart';
import 'package:realunit_wallet/packages/utils/fast_hash.dart';
import 'package:drift/drift.dart';

extension BalanceStorage on AppDatabase {
  Future<int> insertBalance(int id, int chainId, String contractAddress,
          String walletAddress, String balance, String networkMode) =>
      into(balances).insert(BalancesCompanion.insert(
        id: id,
        chainId: chainId,
        contractAddress: contractAddress,
        walletAddress: walletAddress,
        balance: balance,
        networkMode: networkMode,
      ));

  Future<int> updateBalance(int id, String balance) =>
      (update(balances)..where((row) => row.id.equals(id)))
          .write(BalancesCompanion(balance: Value(balance)));

  Future<BalanceData?> getBalance(
          int chainId, String contractAddress, String walletAccount, String networkMode) =>
      (select(balances)
            ..where((row) => row.id
                .equals(fastHash("$walletAccount:$chainId:$contractAddress:$networkMode"))))
          .getSingleOrNull();

  Stream<BalanceData?> watchBalance(int id) =>
      (select(balances)..where((row) => row.id.equals(id))).watchSingleOrNull();
}

@DataClassName("BalanceData")
class Balances extends Table {
  IntColumn get id => integer().unique()();

  IntColumn get chainId => integer()();

  TextColumn get contractAddress => text()();

  TextColumn get walletAddress => text()();

  TextColumn get balance => text()();

  TextColumn get networkMode => text()();
}
