import 'package:alchemist/alchemist.dart';
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

import '../../../helper/helper.dart';

class _MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class _MockTransactionHistoryFilterCubit
    extends MockCubit<TransactionHistoryFilterState>
    implements TransactionHistoryFilterCubit {}

class _MockTransactionHistoryReceiptCubit
    extends MockCubit<TransactionHistoryReceiptState>
    implements TransactionHistoryReceiptCubit {}

class _MockTransactionRepository extends Mock implements TransactionRepository {}

class _MockRealUnitPdfService extends Mock implements RealUnitPdfService {}

class _MockAppStore extends Mock implements AppStore {}

class _MockApiConfig extends Mock implements ApiConfig {}

void main() {
  late _MockSettingsBloc settingsBloc;
  late _MockTransactionHistoryFilterCubit filterCubit;
  late _MockTransactionHistoryReceiptCubit receiptCubit;
  final transactionRepository = _MockTransactionRepository();
  final appStore = _MockAppStore();
  final apiConfig = _MockApiConfig();
  const walletAddress = '0xcabd3f4b10a7089986e708d19140bfc98e5880c0';

  setUpAll(() {
    final getIt = GetIt.instance;
    when(() => apiConfig.asset).thenReturn(realUnitAsset);
    when(() => appStore.apiConfig).thenReturn(apiConfig);
    when(() => appStore.primaryAddress).thenReturn(walletAddress);
    when(() => transactionRepository.watchTransactionsOfAssets(any(), any()))
        .thenAnswer((_) => const Stream<List<Transaction>>.empty());
    getIt.registerSingleton<AppStore>(appStore);
    getIt.registerSingleton<RealUnitPdfService>(_MockRealUnitPdfService());
    getIt.registerSingleton<TransactionRepository>(transactionRepository);
  });

  setUp(() {
    settingsBloc = _MockSettingsBloc();
    filterCubit = _MockTransactionHistoryFilterCubit();
    receiptCubit = _MockTransactionHistoryReceiptCubit();
    when(() => settingsBloc.state).thenReturn(const SettingsState());
    when(() => filterCubit.state).thenReturn(TransactionHistoryFilterState());
    when(() => receiptCubit.state)
        .thenReturn(const TransactionHistoryReceiptInitial());
  });

  tearDownAll(() async => GetIt.instance.reset());

  Widget buildSubject() => MultiBlocProvider(
        providers: [
          BlocProvider<SettingsBloc>.value(value: settingsBloc),
          BlocProvider<TransactionHistoryFilterCubit>.value(value: filterCubit),
          BlocProvider<TransactionHistoryReceiptCubit>.value(value: receiptCubit),
        ],
        child: TransactionHistoryView(walletAddress: walletAddress),
      );

  group('$TransactionHistoryView', () {
    goldenTest(
      'empty filter state',
      fileName: 'transaction_history_page_default',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(buildSubject()),
    );
  });
}
