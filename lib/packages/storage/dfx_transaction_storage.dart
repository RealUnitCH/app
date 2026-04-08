import 'package:drift/drift.dart';
import 'package:realunit_wallet/packages/storage/database.dart';
import 'package:realunit_wallet/packages/storage/transaction_storage.dart';

extension DfxTransactionStorage on AppDatabase {
  Future<int> insertDfxTransactionDetails({
    required String txId,
    required int dfxId,
    String? rate,
    String? inputTxId,
    String? outputTxId,
  }) =>
      into(dfxTransactionDetails).insert(DfxTransactionDetailsCompanion.insert(
        txId: txId,
        dfxId: dfxId,
        rate: Value.absentIfNull(rate),
        inputTxId: Value.absentIfNull(inputTxId),
        outputTxId: Value.absentIfNull(outputTxId),
      ));

  Future<int> updateDfxTransactionDetails({
    required String txId,
    int? dfxId,
    String? rate,
    String? inputTxId,
    String? outputTxId,
  }) =>
      (update(dfxTransactionDetails)..where((row) => row.txId.equals(txId))).write(
        DfxTransactionDetailsCompanion(
          dfxId: Value.absentIfNull(dfxId),
          rate: Value.absentIfNull(rate),
          inputTxId: Value.absentIfNull(inputTxId),
          outputTxId: Value.absentIfNull(outputTxId),
        ),
      );

  Future<DfxTransactionDetailsData?> getDfxTransactionDetails(String txId) =>
      (select(dfxTransactionDetails)..where((row) => row.txId.equals(txId))).getSingleOrNull();

  Future<List<DfxTransactionDetailsData>> get allDfxTransactionDetails =>
      dfxTransactionDetails.all().get();
}

@DataClassName('DfxTransactionDetailsData')
class DfxTransactionDetails extends Table {
  TextColumn get txId => text().unique().references(Transactions, #txId)();

  IntColumn get dfxId => integer().unique()();

  TextColumn get rate => text().nullable()();

  TextColumn get inputTxId => text().nullable()();

  TextColumn get outputTxId => text().nullable()();
}
