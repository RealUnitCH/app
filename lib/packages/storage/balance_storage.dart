import 'package:drift/drift.dart';
import 'package:realunit_wallet/packages/storage/database.dart';
import 'package:realunit_wallet/packages/utils/fast_hash.dart';

extension BalanceStorage on AppDatabase {
  Future<int> insertBalance(
    int id,
    int chainId,
    String contractAddress,
    String walletAddress,
    String balance,
  ) => into(balances).insert(
    BalancesCompanion.insert(
      id: id,
      chainId: chainId,
      contractAddress: contractAddress,
      walletAddress: walletAddress,
      balance: balance,
    ),
  );

  Future<int> updateBalance(int id, String balance) => (update(
    balances,
  )..where((row) => row.id.equals(id))).write(BalancesCompanion(balance: Value(balance)));

  Future<BalanceData?> getBalance(int chainId, String contractAddress, String walletAccount) =>
      (select(balances)
            ..where((row) => row.id.equals(fastHash('$walletAccount:$chainId:$contractAddress'))))
          .getSingleOrNull();

  Stream<BalanceData?> watchBalance(int id) =>
      (select(balances)..where((row) => row.id.equals(id))).watchSingleOrNull();
}

// The schema getters below are read by `drift_dev` at codegen time and the
// resulting column metadata is consumed via the generated mirror class —
// they are not invoked at runtime, so line-coverage instrumentation never
// marks them as executed. The same coverage gap exists on every Drift
// table in the repo. `// coverage:ignore-line` keeps the file at the
// surface the test suite can actually reach.
@DataClassName('BalanceData')
class Balances extends Table {
  IntColumn get id => integer().unique()(); // coverage:ignore-line

  IntColumn get chainId => integer()(); // coverage:ignore-line

  TextColumn get contractAddress => text()(); // coverage:ignore-line

  TextColumn get walletAddress => text()(); // coverage:ignore-line

  TextColumn get balance => text()(); // coverage:ignore-line
}
