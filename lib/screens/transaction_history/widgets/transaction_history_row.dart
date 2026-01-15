import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/models/transaction.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/hide_amount_text.dart';

class TransactionHistoryRow extends StatelessWidget {
  final Transaction transaction;
  final String walletAddress;

  const TransactionHistoryRow({
    super.key,
    required this.transaction,
    required this.walletAddress,
  });

  bool get _isOutbound => transaction.isOutbound(walletAddress);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 10.0,
            children: [
              _isOutbound
                  ? Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                          color: RealUnitColors.brand200,
                          borderRadius: BorderRadius.circular(24.0)),
                      child: const Icon(
                        Icons.horizontal_rule_rounded,
                        color: RealUnitColors.darkBlue,
                      ),
                    )
                  : Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                          color: RealUnitColors.brand200,
                          borderRadius: BorderRadius.circular(24.0)),
                      child: const Icon(
                        Icons.add,
                        color: RealUnitColors.darkBlue,
                      ),
                    ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isOutbound ? S.of(context).transactionSell : S.of(context).transactionBuy,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 20 / 16,
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy | H:mm').format(transaction.timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        color: RealUnitColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
              HideAmountText(
                leadingSymbol: _isOutbound ? '-' : '+',
                amount: transaction.amount,
                decimals: transaction.asset.decimals,
                fractionalDigits: 0,
                trimZeros: false,
                trailingSymbol: transaction.asset.symbol,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 20 / 16,
                ),
              ),
              const Icon(
                Icons.download_outlined,
                color: RealUnitColors.realUnitBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
