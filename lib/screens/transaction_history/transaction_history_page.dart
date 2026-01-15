import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/models/transaction.dart';
import 'package:realunit_wallet/packages/repository/transaction_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/transaction_history_cubit.dart';
import 'package:realunit_wallet/screens/transaction_history/widgets/transaction_date_picker.dart';
import 'package:realunit_wallet/screens/transaction_history/widgets/transaction_history_row.dart';
import 'package:realunit_wallet/styles/colors.dart';

enum DateType { start, end }

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appStore = getIt<AppStore>();

    return BlocProvider(
      create: (context) => TransactionHistoryCubit(
        getIt<TransactionRepository>(),
        asset: appStore.apiConfig.asset,
        walletAddress: appStore.primaryAddress,
      ),
      child: TransactionHistoryView(
        walletAddress: appStore.primaryAddress,
      ),
    );
  }
}

class TransactionHistoryView extends StatefulWidget {
  final String walletAddress;

  const TransactionHistoryView({super.key, required this.walletAddress});

  @override
  State<TransactionHistoryView> createState() => _TransactionHistoryViewState();
}

class _TransactionHistoryViewState extends State<TransactionHistoryView> {
  late DateTime endDate;
  late DateTime startDate;

  @override
  void initState() {
    endDate = DateTime.now();
    startDate = DateTime(endDate.year, endDate.month - 1, endDate.day);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.of(context).transactions,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: BlocBuilder<TransactionHistoryCubit, List<Transaction>>(
        builder: (context, transactions) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              spacing: 20.0,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8.0,
                  children: [
                    Expanded(
                      child: TransactionDatePicker(
                        label: S.of(context).startDate,
                        initialDate: startDate,
                        onPressed: () => _selectDate(DateType.start),
                      ),
                    ),
                    Expanded(
                      child: TransactionDatePicker(
                        label: S.of(context).endDate,
                        initialDate: endDate,
                        onPressed: () => _selectDate(DateType.end),
                      ),
                    ),
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            S.of(context).pdf,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 16 / 12,
                              color: RealUnitColors.neutral500,
                            ),
                          ),
                        ),
                        Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                              color: RealUnitColors.realUnitBlue,
                              borderRadius: BorderRadius.circular(12.0)),
                          child: Icon(
                            Icons.download_outlined,
                            color: RealUnitColors.basic.white,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                ...transactions.reversed.map(
                  (e) => TransactionHistoryRow(
                    transaction: e,
                    walletAddress: widget.walletAddress,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectDate(DateType type) async {
    final initialDate = type == DateType.start ? startDate : endDate;

    final DateTime? pickedDate = await showDatePicker(
        context: context,
        firstDate: DateTime(2025),
        lastDate: DateTime.now(),
        currentDate: initialDate);
    if (pickedDate == null) return;

    setState(() {
      if (type == DateType.start) {
        startDate = pickedDate;
      } else {
        endDate = pickedDate;
      }
    });
  }
}
