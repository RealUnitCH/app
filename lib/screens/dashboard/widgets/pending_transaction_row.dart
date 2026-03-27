import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/transactions/dto/transactions_dto.dart';
import 'package:realunit_wallet/styles/colors.dart';

class PendingTransactionRow extends StatelessWidget {
  final TransactionDto transaction;

  const PendingTransactionRow({
    super.key,
    required this.transaction,
  });

  bool get _isBuy => transaction.type == TransactionType.buy;

  String _getStatusText(BuildContext context) {
    if (transaction.state == TransactionState.waitingForPayment) {
      return S.of(context).transactionWaitingForPayment;
    }
    return S.of(context).transactionPending;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: RealUnitColors.basic.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 10.0,
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: RealUnitColors.brand200,
              borderRadius: BorderRadius.circular(24.0),
            ),
            child: const CupertinoActivityIndicator(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isBuy
                      ? S.of(context).transactionBuy
                      : S.of(context).transactionSell,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  _getStatusText(context),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: RealUnitColors.neutral500,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (transaction.inputAmount != null && transaction.inputAsset != null)
                Text(
                  '${_formatAmount(transaction.inputAmount!)} ${transaction.inputAsset}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              if (transaction.date != null)
                Text(
                  DateFormat('MMM dd, yyyy').format(transaction.date!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: RealUnitColors.neutral500,
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2);
  }
}
