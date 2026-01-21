import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_file/open_file.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/repository/transaction_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_pdf_service.dart';
import 'package:realunit_wallet/screens/transaction_history/cubits/filter/transaction_history_filter_cubit.dart';
import 'package:realunit_wallet/screens/transaction_history/cubits/receipt/transaction_history_receipt_cubit.dart';
import 'package:realunit_wallet/screens/transaction_history/widgets/transaction_date_picker.dart';
import 'package:realunit_wallet/screens/transaction_history/widgets/transaction_history_row.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/date_picker.dart';

enum DateType { start, end }

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appStore = getIt<AppStore>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => TransactionHistoryFilterCubit(
            getIt<TransactionRepository>(),
            asset: appStore.apiConfig.asset,
            walletAddress: appStore.primaryAddress,
          ),
        ),
        BlocProvider(
          create: (context) => TransactionHistoryReceiptCubit(
            getIt<RealUnitPdfService>(),
          ),
        ),
      ],
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
        ),
      ),
      body: BlocListener<TransactionHistoryReceiptCubit, TransactionHistoryReceiptState>(
        listener: (context, state) async {
          if (state is TransactionHistoryReceiptFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: RealUnitColors.status.red600,
              ),
            );
          }
          if (state is TransactionHistoryReceiptSuccess) {
            await OpenFile.open(state.receiptPath);
          }
        },
        child: BlocBuilder<TransactionHistoryFilterCubit, TransactionHistoryFilterState>(
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
                                Icons.download_outlined,
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
                        walletAddress: widget.walletAddress,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _selectDate(DateType type) async {
    final initialDate = type == DateType.start ? startDate : endDate;

    final pickedDate = await DatePicker.pickDate(
      context: context,
      currentDate: initialDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null) return;

    setState(() {
      if (type == DateType.start) {
        startDate = pickedDate;
        context.read<TransactionHistoryFilterCubit>().changeFilter(startDate: pickedDate);
      } else {
        endDate = pickedDate;
        context.read<TransactionHistoryFilterCubit>().changeFilter(endDate: pickedDate);
      }
    });
  }
}
