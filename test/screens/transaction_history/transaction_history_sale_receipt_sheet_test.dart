import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/models/transaction.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/transaction_history/cubits/receipt/transaction_history_receipt_cubit.dart';
import 'package:realunit_wallet/screens/transaction_history/widgets/transaction_history_row.dart';
import 'package:realunit_wallet/styles/currency.dart';
import 'package:realunit_wallet/styles/language.dart';
import 'package:realunit_wallet/styles/themes.dart';

class _MockReceiptCubit extends MockCubit<TransactionHistoryReceiptState>
    implements TransactionHistoryReceiptCubit {}

class _MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

Transaction _tx({TransferCategory? category}) => Transaction(
  height: 0,
  txId: 'tx-42',
  chainId: realUnitAsset.chainId,
  senderAddress: '0xfrom',
  receiverAddress: '0xto',
  amount: BigInt.from(20),
  asset: realUnitAsset,
  type: TransactionTypes.tokenTransfer,
  category: category,
  note: '',
  data: null,
  timestamp: DateTime.utc(2026, 8, 24, 10),
);

void main() {
  late _MockReceiptCubit receiptCubit;
  late _MockSettingsBloc settings;

  setUpAll(() {
    registerFallbackValue(Currency.chf);
    registerFallbackValue(Language.en);
  });

  setUp(() {
    receiptCubit = _MockReceiptCubit();
    when(() => receiptCubit.state).thenReturn(
      const TransactionHistoryReceiptInitial(),
    );
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

    settings = _MockSettingsBloc();
    const settingsState = SettingsState(language: Language.de);
    when(() => settings.state).thenReturn(settingsState);
    whenListen(
      settings,
      const Stream<SettingsState>.empty(),
      initialState: settingsState,
    );
  });

  Future<void> pumpRow(
    WidgetTester tester,
    Transaction tx, {
    required bool isOutbound,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: realUnitTheme,
        locale: const Locale('de'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<TransactionHistoryReceiptCubit>.value(
                value: receiptCubit,
              ),
              BlocProvider<SettingsBloc>.value(value: settings),
            ],
            child: TransactionHistoryRowView(
              transaction: tx,
              isOutbound: isOutbound,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'sale download icon opens a chooser and each tile starts its own receipt',
    (tester) async {
      await pumpRow(
        tester,
        _tx(category: TransferCategory.sale),
        isOutbound: true,
      );

      await tester.tap(find.byIcon(Icons.file_download_outlined));
      await tester.pumpAndSettle();

      expect(find.text('RealUnit-Verkauf'), findsOneWidget);
      expect(find.text('Tausch ZCHF in CHF/EUR'), findsOneWidget);

      await tester.tap(find.text('RealUnit-Verkauf'));
      await tester.pumpAndSettle();

      expect(find.text('RealUnit-Verkauf'), findsNothing);
      verify(
        () => receiptCubit.generateReceipt(
          'tx-42',
          currency: Currency.chf,
          language: Language.de,
        ),
      ).called(1);
      verifyNever(() => receiptCubit.generateExchangeReceipt(any()));

      await tester.tap(find.byIcon(Icons.file_download_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tausch ZCHF in CHF/EUR'));
      await tester.pumpAndSettle();

      expect(find.text('Tausch ZCHF in CHF/EUR'), findsNothing);
      verify(() => receiptCubit.generateExchangeReceipt('tx-42')).called(1);
    },
  );

  testWidgets(
    'purchase download icon generates the RealUnit receipt without a chooser',
    (tester) async {
      await pumpRow(
        tester,
        _tx(category: TransferCategory.purchase),
        isOutbound: false,
      );

      await tester.tap(find.byIcon(Icons.file_download_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Tausch ZCHF in CHF/EUR'), findsNothing);
      verify(
        () => receiptCubit.generateReceipt(
          'tx-42',
          currency: Currency.chf,
          language: Language.de,
        ),
      ).called(1);
      verifyNever(() => receiptCubit.generateExchangeReceipt(any()));
    },
  );

  testWidgets(
    'outbound transfer download generates the RealUnit receipt without a chooser',
    (tester) async {
      await pumpRow(
        tester,
        _tx(category: TransferCategory.transferOut),
        isOutbound: true,
      );

      await tester.tap(find.byIcon(Icons.file_download_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Tausch ZCHF in CHF/EUR'), findsNothing);
      expect(find.text('RealUnit-Verkauf'), findsNothing);
      verify(
        () => receiptCubit.generateReceipt(
          'tx-42',
          currency: Currency.chf,
          language: Language.de,
        ),
      ).called(1);
      verifyNever(() => receiptCubit.generateExchangeReceipt(any()));
    },
  );
}
