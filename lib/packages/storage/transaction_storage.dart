import 'package:drift/drift.dart';
import 'package:realunit_wallet/packages/storage/database.dart';
import 'package:realunit_wallet/packages/utils/fast_hash.dart';

extension TransactionStorage on AppDatabase {
  Future<int> insertTransactions(
    int? dfxId,
    int height,
    String txId,
    int chainId,
    String senderAddress,
    String receiverAddress,
    String amount,
    int asset,
    int type,
    String note,
    String data,
    DateTime timeStamp,
  ) =>
      into(transactions).insert(TransactionsCompanion.insert(
        dfxId: Value(dfxId),
        height: height,
        txId: txId,
        chainId: chainId,
        senderAddress: senderAddress,
        receiverAddress: receiverAddress,
        amount: amount,
        asset: asset,
        type: type,
        note: note,
        data: data,
        timeStamp: timeStamp,
      ));

  Future<int> updateTransaction(
    String txId, {
    int? dfxId,
    int? height,
    int? chainId,
    String? senderAddress,
    String? receiverAddress,
    String? amount,
    int? asset,
    int? type,
    String? note,
    String? data,
    DateTime? timeStamp,
  }) =>
      (update(transactions)..where((row) => row.txId.equals(txId))).write(TransactionsCompanion(
        dfxId: Value.absentIfNull(dfxId),
        height: Value.absentIfNull(height),
        chainId: Value.absentIfNull(chainId),
        senderAddress: Value.absentIfNull(senderAddress),
        receiverAddress: Value.absentIfNull(receiverAddress),
        amount: Value.absentIfNull(amount),
        asset: Value.absentIfNull(asset),
        type: Value.absentIfNull(type),
        note: Value.absentIfNull(note),
        data: Value.absentIfNull(data),
        timeStamp: Value.absentIfNull(timeStamp),
      ));

  Future<List<TransactionData>> getAllTokenTransactions(int chainId, String address) =>
      (select(transactions)..where((row) => row.asset.equals(fastHash('$chainId:$address')))).get();

  Future<List<TransactionData>> get allTransactions => transactions.all().get();

  Stream<List<TransactionData>> watchTransactions() => (select(transactions)
        ..orderBy([(u) => OrderingTerm(expression: u.height, mode: OrderingMode.desc)]))
      .watch();

  Stream<List<TransactionData>> watchTransfersOfAssets(Iterable<int> assets, String wallet) =>
      (select(transactions)
            ..where((row) => Expression.and([
                  row.asset.isIn(assets),
                  row.type.equals(2),
                  Expression.or(
                      [row.senderAddress.equals(wallet), row.receiverAddress.equals(wallet)]),
                ]))
            ..orderBy([(u) => OrderingTerm(expression: u.height, mode: OrderingMode.desc)]))
          .watch();

  Stream<List<TransactionData>> watchTransfersOfAssetsLimit(
          Iterable<int> assets, String wallet, int limit) =>
      (select(transactions)
            ..where((row) => Expression.and([
                  row.asset.isIn(assets),
                  row.type.equals(2),
                  Expression.or(
                      [row.senderAddress.equals(wallet), row.receiverAddress.equals(wallet)]),
                ]))
            ..orderBy([(u) => OrderingTerm(expression: u.timeStamp, mode: OrderingMode.desc)])
            ..limit(limit))
          .watch();

  Stream<List<TransactionData>> watchTransfersOfSavingsLimit(
          Iterable<int> assets, String wallet, int limit) =>
      (select(transactions)
            ..where((row) => Expression.and([
                  row.asset.isIn(assets),
                  row.type.isIn([3, 4]),
                  Expression.or(
                      [row.senderAddress.equals(wallet), row.receiverAddress.equals(wallet)]),
                ]))
            ..orderBy([(u) => OrderingTerm(expression: u.height, mode: OrderingMode.desc)])
            ..limit(limit))
          .watch();

  Future<List<TransactionData>> getLatestTransactions({int limit = 1}) => (select(transactions)
        ..orderBy([(u) => OrderingTerm(expression: u.height, mode: OrderingMode.desc)])
        ..limit(limit))
      .get();

  Future<TransactionData?> getTransaction(String txId) =>
      (select(transactions)..where((row) => row.txId.equals(txId))).getSingleOrNull();
}

@DataClassName('TransactionData')
class Transactions extends Table {
  IntColumn get height => integer()();

  IntColumn get dfxId => integer().unique().nullable()();

  TextColumn get txId => text().unique()();

  IntColumn get chainId => integer()();

  TextColumn get senderAddress => text()();

  TextColumn get receiverAddress => text()();

  TextColumn get amount => text()();

  IntColumn get asset => integer()();

  IntColumn get type => integer()();

  TextColumn get note => text()();

  TextColumn get data => text()();

  DateTimeColumn get timeStamp => dateTime()();
}
