import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/repository/transaction_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/screens/transaction_history/cubits/filter/transaction_history_filter_cubit.dart';
import 'package:realunit_wallet/screens/transaction_history/widgets/transaction_history_row.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/date_picker_field.dart';

enum DateType { start, end }

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appStore = getIt<AppStore>();

    return BlocProvider(
      create: (context) => TransactionHistoryFilterCubit(
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

class TransactionHistoryView extends StatelessWidget {
  TransactionHistoryView({super.key, required this.walletAddress});

  static final _todaysDate = DateTime.now();
  final _endDateModel = _DatePickerModel(_todaysDate);
  final _startDateModel = _DatePickerModel(
    DateTime(_todaysDate.year, _todaysDate.month - 1, _todaysDate.day),
  );

  final String walletAddress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.of(context).transactions,
        ),
      ),
      body: BlocBuilder<TransactionHistoryFilterCubit, TransactionHistoryFilterState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                spacing: 20.0,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8.0,
                    children: [
                      Expanded(
                        child: DatePickerField(
                          label: S.of(context).startDate,
                          initialDate: _startDateModel.value,
                          firstDate: DateTime(2025),
                          lastDate: _todaysDate,
                          onDateSelected: (date) {
                            _startDateModel.setDate(date);
                            context
                                .read<TransactionHistoryFilterCubit>()
                                .changeFilter(startDate: date);
                          },
                        ),
                      ),
                      Expanded(
                        child: DatePickerField(
                          label: S.of(context).endDate,
                          initialDate: _endDateModel.value,
                          firstDate: DateTime(2025),
                          lastDate: _todaysDate,
                          onDateSelected: (date) {
                            _endDateModel.setDate(date);
                            context
                                .read<TransactionHistoryFilterCubit>()
                                .changeFilter(endDate: date);
                          },
                        ),
                      ),
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
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
                              Icons.file_download_outlined,
                              color: RealUnitColors.basic.white,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                  ...state.filtered.reversed.map(
                    (transaction) => TransactionHistoryRow(
                      transaction: transaction,
                      walletAddress: walletAddress,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DatePickerModel extends ValueNotifier<DateTime> {
  _DatePickerModel(super.initialDate);

  void setDate(DateTime date) => value = date;
}
