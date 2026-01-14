import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/models/transaction.dart';
import 'package:realunit_wallet/packages/repository/transaction_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/transaction_history_cubit.dart';
import 'package:realunit_wallet/screens/dashboard/widgets/transaction_row.dart';
import 'package:realunit_wallet/styles/colors.dart';

class DashboardTransactionHistory extends StatelessWidget {
  const DashboardTransactionHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final appStore = getIt<AppStore>();

    return BlocProvider(
      create: (context) => TransactionHistoryCubit(
        getIt<TransactionRepository>(),
        asset: appStore.apiConfig.asset,
        walletAddress: appStore.primaryAddress,
      ),
      child: DashboardTransactionHistoryView(
        walletAddress: appStore.primaryAddress,
      ),
    );
  }
}

class DashboardTransactionHistoryView extends StatelessWidget {
  const DashboardTransactionHistoryView({super.key, required this.walletAddress});

  final String walletAddress;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionHistoryCubit, List<Transaction>>(
      builder: (context, transactions) {
        if (transactions.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8.0,
            children: [
              Text(
                S.of(context).latestTransactions,
                style: const TextStyle(
                  color: RealUnitColors.neutral500,
                  fontSize: 12,
                  height: 12 / 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RealUnitColors.basic.white,
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Column(
                  spacing: 12.0,
                  children: [
                    ...transactions.reversed.take(3).map((e) => TransactionRow(
                          transaction: e,
                          walletAddress: walletAddress,
                        )),
                    TextButton(
                      onPressed: () => context.push('/dashboard/transactions'),
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 22),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          alignment: Alignment.centerLeft),
                      child: Text(
                        S.of(context).transactionHistory,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
