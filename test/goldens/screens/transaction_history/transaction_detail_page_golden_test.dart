import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/models/transaction.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/transaction_history/cubits/receipt/transaction_history_receipt_cubit.dart';
import 'package:realunit_wallet/screens/transaction_history/transaction_detail_page.dart';
import 'package:realunit_wallet/styles/currency.dart';
import 'package:realunit_wallet/styles/language.dart';

import '../../../helper/helper.dart';

class _MockTransactionHistoryReceiptCubit
    extends MockCubit<TransactionHistoryReceiptState>
    implements TransactionHistoryReceiptCubit {}

void main() {
  // The timestamp is formatted in the runner's local zone, same as the other
  // transaction-history goldens. This test does not commit a PNG; the
  // regenerate workflow does.

  late MockSettingsBloc settingsBloc;
  late _MockTransactionHistoryReceiptCubit receiptCubit;

  final sale = Transaction(
    height: 0,
    txId: 'tx-sale-sheet',
    chainId: realUnitAsset.chainId,
    senderAddress: '0x1111111111111111111111111111111111111111',
    receiverAddress: '0x2222222222222222222222222222222222222222',
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
    when(
      () => settingsBloc.state,
    ).thenReturn(const SettingsState(language: Language.de));

    receiptCubit = _MockTransactionHistoryReceiptCubit();
    when(
      () => receiptCubit.state,
    ).thenReturn(const TransactionHistoryReceiptInitial());
    when(
      () => receiptCubit.generateReceipt(
        any(),
        currency: any(named: 'currency'),
        language: any(named: 'language'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => receiptCubit.generateExchangeReceipt(any()),
    ).thenAnswer((_) async {});
  });

  group('$TransactionDetailView', () {
    goldenTest(
      'sale detail page with two receipt buttons',
      fileName: 'transaction_detail_sale',
      constraints: phoneConstraints,
      pumpBeforeTest: (tester) async {
        await tester.pumpAndSettle();
        expect(find.text('Verkauf'), findsOneWidget);
        expect(find.text('Belege'), findsOneWidget);
        expect(find.text('RealUnit-Verkauf'), findsOneWidget);
        expect(find.text('Tausch ZCHF in CHF/EUR'), findsOneWidget);
        expect(find.text('tx-sale-sheet'), findsNothing);
        expect(find.text('Absender'), findsNothing);
        expect(find.text('Empfänger'), findsNothing);
      },
      builder: () => wrapForGolden(
        MultiBlocProvider(
          providers: [
            BlocProvider<SettingsBloc>.value(value: settingsBloc),
            BlocProvider<TransactionHistoryReceiptCubit>.value(
              value: receiptCubit,
            ),
          ],
          child: TransactionDetailView(
            args: TransactionDetailArgs(
              transaction: sale,
              walletAddress: '0x1111111111111111111111111111111111111111',
            ),
          ),
        ),
      ),
    );
  });
}
