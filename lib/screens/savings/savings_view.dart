import 'package:deuro_wallet/di.dart';
import 'package:deuro_wallet/generated/i18n.dart';
import 'package:deuro_wallet/models/transaction.dart';
import 'package:deuro_wallet/packages/repository/transaction_repository.dart';
import 'package:deuro_wallet/packages/service/app_store.dart';
import 'package:deuro_wallet/screens/dashboard/widgets/section_transaction_history.dart';
import 'package:deuro_wallet/screens/savings/bloc/savings_bloc.dart';
import 'package:deuro_wallet/screens/savings/bloc/transaction_history_cubit.dart';
import 'package:deuro_wallet/screens/savings/widgets/section_balance.dart';
import 'package:deuro_wallet/styles/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SavingsView extends StatelessWidget {
  SavingsView(this._appStore, {super.key}) {
    transactionHistoryCubit =
        TransactionHistoryCubit(getIt<TransactionRepository>(), walletAddress);
  }

  final AppStore _appStore;
  late final TransactionHistoryCubit transactionHistoryCubit;

  String get walletAddress => _appStore.primaryAddress;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          top: false,
          child: BlocBuilder<SavingsBloc, SavingsState>(
            builder: (context, state) => Column(children: [
              SectionBalance(
                balance: BigInt.parse(state.amount, radix: 16),
                interestRate: BigInt.parse(state.interestRate, radix: 16),
                collectedInterest:
                    BigInt.parse(state.accruedInterest, radix: 16),
                isEnabled: state.isEnabled,
              ),
              Expanded(
                child: CustomScrollView(slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(children: <Widget>[
                        if (state.isCached)
                          Container(
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: kContainerCardStyle,
                            child:
                                Row(mainAxisSize: MainAxisSize.max, children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 20),
                                child: Icon(Icons.warning, color: Colors.amber),
                              ),
                              Text(S.of(context).savings_data_outdated),
                            ]),
                          ),
                        BlocBuilder<TransactionHistoryCubit, List<Transaction>>(
                          bloc: transactionHistoryCubit,
                          builder: (context, state) =>
                              SectionTransactionHistory(
                            transactions: state,
                            walletAddress: walletAddress,
                            hasShowAll: state.length == 5,
                          ),
                        ),
                      ]),
                    ),
                  )
                ]),
              )
            ]),
          ),
        ),
      );
}
