import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/transaction_history/cubits/receipt/transaction_history_receipt_cubit.dart';

Future<void> showSaleReceiptSheet(BuildContext context, String txId) async {
  final cubit = context.read<TransactionHistoryReceiptCubit>();
  final settings = context.read<SettingsBloc>().state;
  final currency = settings.currency;
  final language = settings.language;

  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const .all(8.0),
        child: Column(
          mainAxisSize: .min,
          children: [
            Text(S.of(sheetContext).saleReceiptSheetTitle),
            ListTile(
              title: Text(S.of(sheetContext).saleReceiptRealunit),
              onTap: () {
                Navigator.pop(sheetContext);
                cubit.generateReceipt(
                  txId,
                  currency: currency,
                  language: language,
                );
              },
            ),
            ListTile(
              title: Text(S.of(sheetContext).saleReceiptExchange),
              onTap: () {
                Navigator.pop(sheetContext);
                cubit.generateExchangeReceipt(txId);
              },
            ),
          ],
        ),
      ),
    ),
  );
}
