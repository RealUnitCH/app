import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/email/cubits/email_step/kyc_email_step_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/email/kyc_email_page.dart';
import 'package:realunit_wallet/widgets/form/labeled_text_field.dart';

import '../../../helper/pump_app.dart';

class MockKycEmailStepCubit extends MockCubit<KycEmailStepState> implements KycEmailStepCubit {}

class MockKycCubit extends MockCubit<KycState> implements KycCubit {}

class MockRealUnitRegistrationService extends Mock implements RealUnitRegistrationService {}

void main() {
  late KycEmailStepCubit kycEmailStepCubit;
  late KycCubit kycCubit;

  setUp(() {
    kycEmailStepCubit = MockKycEmailStepCubit();
    kycCubit = MockKycCubit();

    when(() => kycEmailStepCubit.state).thenReturn(const KycEmailStepInitial());
    when(() => kycCubit.state).thenReturn(const KycInitial());
    when(() => kycCubit.checkKyc()).thenAnswer((_) => Future.value());
  });

  void setupDependencyInjection() {
    final getIt = GetIt.instance;
    getIt.registerSingleton<RealUnitRegistrationService>(MockRealUnitRegistrationService());
  }

  setUpAll(() {
    setupDependencyInjection();
  });

  tearDownAll(() async => await GetIt.instance.reset());

  Widget buildSubject(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: kycCubit),
        BlocProvider.value(value: kycEmailStepCubit),
      ],
      child: child,
    );
  }

  group('$KycEmailPage', () {
    testWidgets('renders $KycEmailView', (tester) async {
      await tester.pumpApp(const KycEmailPage());

      expect(find.byType(KycEmailView), findsOne);
    });
  });

  group('$KycEmailView', () {
    testWidgets('is rendered initially correctly', (tester) async {
      await tester.pumpApp(buildSubject(const KycEmailView()));

      expect(find.byType(LabeledTextField), findsOne);
      final buttonWidget = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(buttonWidget.onPressed, isNotNull);
    });

    testWidgets('is rendered correctly when loading', (tester) async {
      when(() => kycEmailStepCubit.state).thenReturn(const KycEmailStepLoading());

      await tester.pumpApp(buildSubject(const KycEmailView()));

      expect(find.byType(LabeledTextField), findsOne);
      final buttonWidget = tester.widget<FilledButton>(find.bySubtype<FilledButton>());
      expect(buttonWidget.onPressed, isNull);
    });
  });

  group('$BlocListener', () {
    testWidgets('triggers checkKyc if submitting successes', (tester) async {
      whenListen(
        kycEmailStepCubit,
        Stream.fromIterable([
          const KycEmailStepSuccess(.emailRegistered),
        ]),
        initialState: const KycEmailStepInitial(),
      );

      await tester.pumpApp(buildSubject(const KycEmailView()));
      await tester.pump();

      verify(() => kycCubit.checkKyc()).called(1);
    });

    testWidgets('shows SnackBar if submitting fails', (tester) async {
      whenListen(
        kycEmailStepCubit,
        Stream.fromIterable([const KycEmailStepFailure(.emailDoesNotMatch, 'fail')]),
        initialState: const KycEmailStepInitial(),
      );

      await tester.pumpApp(buildSubject(const KycEmailView()));
      await tester.pump();

      expect(find.byType(SnackBar), findsOne);
    });
  });
}
