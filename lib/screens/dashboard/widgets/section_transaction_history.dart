import 'package:deuro_wallet/di.dart';
import 'package:deuro_wallet/generated/i18n.dart';
import 'package:deuro_wallet/models/transaction.dart';
import 'package:deuro_wallet/packages/service/transaction_history_service.dart';
import 'package:deuro_wallet/screens/dashboard/widgets/transaction_row.dart';
import 'package:deuro_wallet/styles/colors.dart';
import 'package:deuro_wallet/styles/styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Text(
                    S.of(context).transactions,
                    style: kSubtitleTextStyle,
                  ),
                  Spacer(),
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: Colors.white10.withAlpha(50),
                    child: IconButton(
                      onPressed: () =>
                          getIt<TransactionHistoryService>().ponderBasedSync(),
                      iconSize: 18,
                      color: DEuroColors.neutralGrey,
                      icon: Icon(Icons.refresh),
                    ),
                  ),
                ],
              ),
            ),
            ...transactions.map((e) => TransactionRow(
                  transaction: e,
                  walletAddress: walletAddress,
                )),
            if (hasShowAll) ...[
              TextButton(
                onPressed: () => context.push("/dashboard/transactions"),
                child: Text(
                  S.of(context).show_all,
                  style: TextStyle(
                    fontSize: 17,
                    fontFamily: "Satoshi Bold",
                    color: DEuroColors.dEuroGold,
                  ),
                ),
              )
            ]
          ],
        ),
      );
}
