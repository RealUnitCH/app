import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_financial_data_dto.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/financial_data/cubits/kyc_financial_data_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/financial_data/kyc_financial_data_page.dart';
import 'package:realunit_wallet/screens/kyc/steps/financial_data/subpages/kyc_financial_data_failure_page.dart';
import 'package:realunit_wallet/screens/kyc/steps/financial_data/subpages/kyc_financial_data_loading_page.dart';
import 'package:realunit_wallet/screens/kyc/steps/financial_data/subpages/kyc_financial_data_questions_page.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';

import '../../../helper/pump_app.dart';

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState> implements SettingsBloc {}

class MockKycFinancialDataCubit extends MockCubit<KycFinancialDataState>
    implements KycFinancialDataCubit {}

class MockKycCubit extends MockCubit<KycState> implements KycCubit {}

class MockDfxKycService extends Mock implements DfxKycService {}

void main() {
  late MockSettingsBloc settingsBloc;
  late KycFinancialDataCubit kycFinancialDataCubit;
  late KycCubit kycCubit;
  final String url = 'https://example.com';

  setUp(() {
    settingsBloc = MockSettingsBloc();
    kycFinancialDataCubit = MockKycFinancialDataCubit();
    kycCubit = MockKycCubit();

    when(() => settingsBloc.state).thenReturn(const SettingsState());
    when(() => kycFinancialDataCubit.state).thenReturn(const KycFinancialDataInitial());
    when(() => kycCubit.state).thenReturn(const KycInitial());
    when(() => kycCubit.checkKyc()).thenAnswer((_) => Future.value());
  });

  void setupDependencyInjection() {
    final getIt = GetIt.instance;
    getIt.registerSingleton<DfxKycService>(MockDfxKycService());
  }

  setUpAll(() {
    setupDependencyInjection();
  });

  tearDownAll(() async => await GetIt.instance.reset());

  Widget buildSubject(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>.value(value: settingsBloc),
        BlocProvider.value(value: kycFinancialDataCubit),
        BlocProvider.value(value: kycCubit),
      ],
      child: child,
    );
  }

  group('$KycFinancialDataPage', () {
    testWidgets('renders $KycFinancialDataView', (tester) async {
      await tester.pumpApp(
        BlocProvider<SettingsBloc>.value(
          value: settingsBloc,
          child: KycFinancialDataPage(url: url),
        ),
      );

      expect(find.byType(KycFinancialDataView), findsOne);
    });
  });

  group('$KycFinancialDataView', () {
    testWidgets('is initially rendered correctly', (tester) async {
      await tester.pumpApp(buildSubject(const KycFinancialDataView()));

      expect(find.byType(Scaffold), findsOne);
    });

    testWidgets('is rendered correctly when financialData is loading', (tester) async {
      when(() => kycFinancialDataCubit.state).thenReturn(const KycFinancialDataLoading());

      await tester.pumpApp(buildSubject(const KycFinancialDataView()));

      expect(find.byType(KycFinancialDataLoadingPage), findsOne);
    });

    testWidgets('is rendered correctly when financialData was submitted', (tester) async {
      when(() => kycFinancialDataCubit.state).thenReturn(const KycFinancialDataSubmitting());

      await tester.pumpApp(buildSubject(const KycFinancialDataView()));

      expect(find.byType(KycFinancialDataLoadingPage), findsOne);
    });

    testWidgets('is rendered correctly when loading financialData failed', (tester) async {
      when(() => kycFinancialDataCubit.state).thenReturn(const KycFinancialDataFailure('fail'));

      await tester.pumpApp(buildSubject(const KycFinancialDataView()));

      expect(find.byType(KycFinancialDataFailurePage), findsOne);
    });

    testWidgets('is rendered correctly when financialData was loaded successfully', (tester) async {
      when(() => kycFinancialDataCubit.state).thenReturn(
        const KycFinancialDataLoadedSuccess(
          allQuestions: [KycFinancialQuestion(key: '', type: QuestionType.text, title: '')],
          visibleQuestions: [KycFinancialQuestion(key: '', type: QuestionType.text, title: '')],
          responses: {},
          currentIndex: 0,
          url: '',
        ),
      );

      await tester.pumpApp(buildSubject(const KycFinancialDataView()));

      expect(find.byType(KycFinancialDataQuestionsPage), findsOne);
    });
  });

  group('$BlocListener', () {
    testWidgets('triggers checkKyc if submitting successes', (tester) async {
      whenListen(
        kycFinancialDataCubit,
        Stream.fromIterable([
          const KycFinancialDataSubmitSuccess(),
        ]),
        initialState: const KycFinancialDataInitial(),
      );

      await tester.pumpApp(buildSubject(const KycFinancialDataView()));
      await tester.pump();

      verify(() => kycCubit.checkKyc()).called(1);
    });

    testWidgets('shows SnackBar if submitting fails', (tester) async {
      whenListen(
        kycFinancialDataCubit,
        Stream.fromIterable([const KycFinancialDataFailure('fail')]),
        initialState: const KycFinancialDataInitial(),
      );

      await tester.pumpApp(buildSubject(const KycFinancialDataView()));
      await tester.pump();

      expect(find.byType(SnackBar), findsOne);
    });
  });
}
