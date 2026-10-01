import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/models/transaction.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/transaction_history/cubits/receipt/transaction_history_receipt_cubit.dart';
import 'package:realunit_wallet/screens/transaction_history/widgets/transaction_history_row.dart';
import 'package:realunit_wallet/styles/currency.dart';
import 'package:realunit_wallet/styles/language.dart';

import '../../../helper/helper.dart';

class _MockTransactionHistoryReceiptCubit extends MockCubit<TransactionHistoryReceiptState>
    implements TransactionHistoryReceiptCubit {}

void main() {
  // The row timestamp is formatted in the runner's local zone, same as the
  // other transaction-history goldens. This test does not commit a PNG; the
  // regenerate workflow does.

  late MockSettingsBloc settingsBloc;
  late _MockTransactionHistoryReceiptCubit receiptCubit;

  final sale = Transaction(
    height: 0,
    txId: 'tx-sale-sheet',
    chainId: realUnitAsset.chainId,
    senderAddress: '0xfrom',
    receiverAddress: '0xto',
    amount: BigInt.from(20),
    asset: realUnitAsset,
    type: TransactionTypes.tokenTransfer,
    category: TransferCategory.sale,
    note: '',
    data: null,
    timestamp: DateTime.utc(2026, 8, 24, 10),
  );

  setUpAll(() {
    registerFallbackValue(Currency.chf);
    registerFallbackValue(Language.en);
  });

  setUp(() {
    settingsBloc = MockSettingsBloc();
    when(() => settingsBloc.state).thenReturn(const SettingsState(language: Language.de));

    receiptCubit = _MockTransactionHistoryReceiptCubit();
    when(() => receiptCubit.state).thenReturn(const TransactionHistoryReceiptInitial());
    when(
      () => receiptCubit.generateReceipt(
        any(),
        currency: any(named: 'currency'),
        language: any(named: 'language'),
      ),
    ).thenAnswer((_) async {});
    when(() => receiptCubit.generateExchangeReceipt(any())).thenAnswer((_) async {});
  });

  group('$TransactionHistoryRowView', () {
    goldenTest(
      'sale download icon opens the receipt sheet',
      fileName: 'transaction_history_sale_receipt_sheet',
      constraints: phoneConstraints,
      pumpBeforeTest: (tester) async {
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.file_download_outlined));
        await tester.pumpAndSettle();
        expect(find.text('Belege'), findsOneWidget);
        expect(find.text('RealUnit-Verkauf'), findsOneWidget);
        expect(find.text('Tausch ZCHF in CHF/EUR'), findsOneWidget);
      },
      builder: () => wrapForGolden(
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: MultiBlocProvider(
              providers: [
                BlocProvider<SettingsBloc>.value(value: settingsBloc),
                BlocProvider<TransactionHistoryReceiptCubit>.value(value: receiptCubit),
              ],
              child: TransactionHistoryRowView(transaction: sale, isOutbound: true),
            ),
          ),
        ),
      ),
    );
  });
}
