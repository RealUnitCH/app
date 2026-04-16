import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/models/transaction.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/repository/transaction_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_pdf_service.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/transaction_history/cubits/filter/transaction_history_filter_cubit.dart';
import 'package:realunit_wallet/screens/transaction_history/cubits/receipt/transaction_history_receipt_cubit.dart';
import 'package:realunit_wallet/screens/transaction_history/transaction_history_page.dart';
import 'package:realunit_wallet/screens/transaction_history/widgets/transaction_history_download_button.dart';
import 'package:realunit_wallet/screens/transaction_history/widgets/transaction_history_row.dart';
import 'package:realunit_wallet/widgets/date_picker_field.dart';

import '../../helper/helper.dart';

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState> implements SettingsBloc {}

class MockTransactionHistoryFilterCubit extends MockCubit<TransactionHistoryFilterState>
    implements TransactionHistoryFilterCubit {}

class MockTransactionHistoryReceiptCubit extends MockCubit<TransactionHistoryReceiptState>
    implements TransactionHistoryReceiptCubit {}

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockRealUnitPdfService extends Mock implements RealUnitPdfService {}

class MockAppStore extends Mock implements AppStore {}

class MockApiConfig extends Mock implements ApiConfig {}

void main() {
  late MockSettingsBloc settingsBloc;
  late TransactionHistoryFilterCubit transactionHistoryFilterCubit;
  late TransactionHistoryReceiptCubit transactionHistoryReceiptCubit;
  final TransactionRepository transactionRepository = MockTransactionRepository();
  final AppStore appStore = MockAppStore();
  final ApiConfig apiConfig = MockApiConfig();
  final String walletAddress = '0xcabd3f4b10a7089986e708d19140bfc98e5880c0';

  setUp(() {
    settingsBloc = MockSettingsBloc();
    transactionHistoryFilterCubit = MockTransactionHistoryFilterCubit();
    transactionHistoryReceiptCubit = MockTransactionHistoryReceiptCubit();

    when(() => settingsBloc.state).thenReturn(const SettingsState());
    when(() => transactionHistoryFilterCubit.state).thenReturn(TransactionHistoryFilterState());
    when(
      () => transactionHistoryReceiptCubit.state,
    ).thenReturn(const TransactionHistoryReceiptInitial());
    when(
      () => transactionRepository.watchTransactionsOfAssets(any(), any()),
    ).thenAnswer((_) => const Stream<List<Transaction>>.empty());
    when(() => apiConfig.asset).thenReturn(realUnitAsset);
    when(() => appStore.primaryAddress).thenReturn(walletAddress);
    when(() => appStore.apiConfig).thenReturn(apiConfig);
  });

  Future<void> setupDependencyInjection() async {
    final getIt = GetIt.instance;
    getIt.registerSingleton<AppStore>(appStore);
    getIt.registerSingleton<RealUnitPdfService>(MockRealUnitPdfService());
    getIt.registerSingleton<TransactionRepository>(transactionRepository);
  }

  setUpAll(() async => await setupDependencyInjection());

  tearDownAll(() async => await GetIt.instance.reset());

  Widget buildSubject() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>.value(value: settingsBloc),
        BlocProvider<TransactionHistoryFilterCubit>.value(value: transactionHistoryFilterCubit),
        BlocProvider<TransactionHistoryReceiptCubit>.value(value: transactionHistoryReceiptCubit),
      ],
      child: TransactionHistoryView(
        walletAddress: walletAddress,
      ),
    );
  }

  group('$TransactionHistoryPage', () {
    testWidgets('renders $TransactionHistoryView', (tester) async {
      await tester.pumpApp(const TransactionHistoryPage());

      expect(find.byType(TransactionHistoryView), findsOne);
    });
  });

  group('$TransactionHistoryView', () {
    testWidgets('renders initially correctly', (tester) async {
      await tester.pumpApp(buildSubject());

      expect(find.byType(DatePickerField), findsNWidgets(2));
      expect(find.byType(TransactionHistoryDownloadButton), findsOne);
    });

    testWidgets('renders $TransactionHistoryRow for each Transaction', (tester) async {
      final transactions = [
        Transaction(
          height: 0,
          txId: 'txId',
          chainId: 0,
          senderAddress: '0x0001114b1da7089986e7e8d19140bfc98e5880c2',
          receiverAddress: '0x0001114b1da7089986e7e8d19140bfc98e5880c2',
          amount: BigInt.from(5),
          asset: realUnitAsset,
          type: TransactionTypes.transfer,
          data: '',
          note: '',
          timestamp: DateTime.now(),
        ),
        Transaction(
          height: 0,
          txId: 'txId',
          chainId: 1,
          senderAddress: '0x0001114b1da7089986e7e8d19140bfc98e5880c2',
          receiverAddress: '0x0001114b1da7089986e7e8d19140bfc98e5880c2',
          amount: BigInt.from(5),
          asset: realUnitAsset,
          type: TransactionTypes.transfer,
          data: '',
          note: '',
          timestamp: DateTime.now(),
        ),
      ];

      when(
        () => transactionHistoryFilterCubit.state,
      ).thenReturn(TransactionHistoryFilterState(all: transactions, filtered: transactions));

      await tester.pumpApp(buildSubject());

      expect(find.byType(TransactionHistoryRow), findsNWidgets(transactions.length));
    });
  });
}
