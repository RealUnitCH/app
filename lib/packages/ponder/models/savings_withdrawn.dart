import 'package:realunit_wallet/models/transaction.dart';
import 'package:realunit_wallet/packages/ponder/models/ponder_tx.dart';

class SavingsWithdrawn extends PonderTx {
  const SavingsWithdrawn({
    required super.created,
    required super.blockheight,
    required super.txHash,
    required super.account,
    required super.amount,
  });

  static List<SavingsWithdrawn> fromJson(Map<String, dynamic> query) {
    final result = <SavingsWithdrawn>[];
    final items = query['savingsWithdrawns']['items'] as List<dynamic>;

    for (final itemRaw in items) {
      final item = itemRaw as Map<String, dynamic>;
      result.add(SavingsWithdrawn(
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
  TransactionTypes get txType => TransactionTypes.savingsRemove;
}
