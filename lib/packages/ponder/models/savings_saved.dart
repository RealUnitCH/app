import 'package:realunit_wallet/models/transaction.dart';
import 'package:realunit_wallet/packages/ponder/models/ponder_tx.dart';

class SavingsSaved extends PonderTx {
  const SavingsSaved({
    required super.created,
    required super.blockheight,
    required super.txHash,
    required super.account,
    required super.amount,
  });

  static List<SavingsSaved> fromJson(Map<String, dynamic> query) {
    final result = <SavingsSaved>[];
    final items = query['savingsSaveds']['items'] as List<dynamic>;

    for (final itemRaw in items) {
      final item = itemRaw as Map<String, dynamic>;
      result.add(SavingsSaved(
        created: BigInt.parse(item['created']),
        blockheight: BigInt.parse(item['blockheight']),
        txHash: item['txHash'],
        account: item['account'],
        amount: BigInt.parse(item['amount']),
      ));
    }

    return result;
  }

  @override
  TransactionTypes get txType => TransactionTypes.savingsAdd;
}
