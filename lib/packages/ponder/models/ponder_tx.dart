import 'package:realunit_wallet/models/transaction.dart';

abstract class PonderTx {
  final BigInt created;
  final BigInt blockheight;
  final String txHash;
  final String account;
  final BigInt amount;

  const PonderTx({
    required this.created,
    required this.blockheight,
    required this.txHash,
    required this.account,
    required this.amount,
  });

  TransactionTypes get txType;
}
