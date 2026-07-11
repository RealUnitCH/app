import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/nationality/cubit/kyc_nationality/kyc_nationality_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/nationality/kyc_nationality_page.dart';
import 'package:realunit_wallet/widgets/form/country_field.dart';

import '../../../helper/country_fixture.dart';
import '../../../helper/pump_app.dart';

class MockKycNationalityCubit extends MockCubit<KycNationalityState>
    implements KycNationalityCubit {}

class MockKycCubit extends MockCubit<KycState> implements KycCubit {}

class MockDfxKycService extends Mock implements DfxKycService {}

void main() {
  late KycNationalityCubit kycNationalityCubit;
  late KycCubit kycCubit;
  final String url = 'https://example.com';

  setUp(() {
    kycNationalityCubit = MockKycNationalityCubit();
    kycCubit = MockKycCubit();

    when(() => kycNationalityCubit.state).thenReturn(const KycNationalityInitial());
    when(() => kycCubit.state).thenReturn(const KycInitial());
    when(() => kycCubit.checkKyc()).thenAnswer((_) => Future.value());
  });

  void setupDependencyInjection() {
    final getIt = GetIt.instance;
    getIt.registerSingleton<DfxKycService>(MockDfxKycService());
    getIt.registerSingleton<DfxCountryService>(fixtureCountryService());
  }

  setUpAll(() {
    setupDependencyInjection();
  });

  tearDownAll(() async => await GetIt.instance.reset());

  Widget buildSubject(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: kycNationalityCubit),
        BlocProvider.value(value: kycCubit),
      ],
      child: child,
    );
  }

  group('$KycNationalityPage', () {
    testWidgets('renders $KycNationalityView', (tester) async {
      await tester.pumpApp(KycNationalityPage(url: url));

      expect(find.byType(KycNationalityView), findsOne);
    });
  });

  group('$KycNationalityView', () {
    testWidgets('is initially rendered correctly', (tester) async {
      await tester.pumpApp(buildSubject(KycNationalityView(url: url)));

      expect(find.byType(CountryField), findsOne);
      expect(find.byType(FilledButton), findsOne);
    });
  });

  group('$BlocListener', () {
    testWidgets('triggers checkKyc if submitting successes', (tester) async {
      whenListen(
        kycNationalityCubit,
        Stream.fromIterable([
          const KycNationalitySuccess(),
        ]),
        initialState: const KycNationalityInitial(),
      );

      await tester.pumpApp(buildSubject(KycNationalityView(url: url)));
      await tester.pump();

      verify(() => kycCubit.checkKyc()).called(1);
    });

    testWidgets('shows SnackBar if submitting fails', (tester) async {
      whenListen(
        kycNationalityCubit,
        Stream.fromIterable([const KycNationalityFailure('fail')]),
        initialState: const KycNationalityInitial(),
      );

      await tester.pumpApp(buildSubject(KycNationalityView(url: url)));
      await tester.pump();

      expect(find.byType(SnackBar), findsOne);
    });
  });
}
