import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/transaction_history/cubits/receipt/transaction_history_receipt_cubit.dart';
import 'package:realunit_wallet/widgets/handlebars.dart';

Future<void> showSaleReceiptSheet(BuildContext context, String txId) async {
  final cubit = context.read<TransactionHistoryReceiptCubit>();
  final settings = context.read<SettingsBloc>().state;
  final currency = settings.currency;
  final language = settings.language;

  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Handlebars.horizontal(sheetContext, margin: const EdgeInsets.only(top: 5), width: 36),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Text(
              S.of(sheetContext).saleReceiptSheetTitle,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          ListTile(
            title: Text(S.of(sheetContext).saleReceiptRealunit),
            onTap: () {
              Navigator.pop(sheetContext);
              cubit.generateReceipt(txId, currency: currency, language: language);
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
  );
}
