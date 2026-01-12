import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/models/transaction.dart';
import 'package:realunit_wallet/screens/dashboard/widgets/transaction_row.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/styles.dart';

class SectionTransactionHistory extends StatelessWidget {
  const SectionTransactionHistory({
    super.key,
    required this.transactions,
    required this.walletAddress,
    required this.hasShowAll,
  });

  final List<Transaction> transactions;
  final bool hasShowAll;
  final String walletAddress;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 12),
        width: double.infinity,
        decoration: kContainerCardStyle,
        child: Column(
          children: [
            ...transactions.map((e) => TransactionRow(
                  transaction: e,
                  walletAddress: walletAddress,
                )),
            if (hasShowAll) ...[
              TextButton(
                onPressed: () => context.push('/dashboard/transactions'),
                child: Text(
                  S.of(context).show_all,
                  style: const TextStyle(
                    fontSize: 17,
                    fontFamily: 'Satoshi Bold',
                    color: DEuroColors.dEuroGold,
                  ),
                ),
              )
            ]
          ],
        ),
      );
}
