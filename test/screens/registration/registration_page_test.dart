import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_status.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/cubits/registration_step/registration_step_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/cubits/registration_submit/registration_submit_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/registration_page.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/steps/registration_address_step.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/steps/registration_email_step.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/steps/registration_personal_step.dart';

import '../../helper/helper.dart';

class MockRegistrationStepCubit extends MockCubit<RegistrationStepState>
    implements RegistrationStepCubit {}

class MockRegistrationSubmitCubit extends MockCubit<RegistrationSubmitState>
    implements RegistrationSubmitCubit {}

class MockKycCubit extends MockCubit<KycState> implements KycCubit {}

class MockDfxRegistrationService extends Mock implements RealUnitRegistrationService {}

class MockDfxCountryService extends Mock implements DfxCountryService {}

void main() {
  late RegistrationStepCubit registrationStepCubit;
  late RegistrationSubmitCubit registrationSubmitCubit;
  late KycCubit kycCubit;

  setUp(() {
    registrationStepCubit = MockRegistrationStepCubit();
    registrationSubmitCubit = MockRegistrationSubmitCubit();
    kycCubit = MockKycCubit();

    when(() => registrationStepCubit.state).thenReturn(
      const RegistrationStepState(
        step: RegistrationStep.email,
        steps: [
          RegistrationStep.email,
          RegistrationStep.personal,
          RegistrationStep.address,
        ],
      ),
    );
    when(() => registrationSubmitCubit.state).thenReturn(RegistrationSubmitInitial());
    when(() => kycCubit.state).thenReturn(const KycInitial());
    when(() => kycCubit.checkKyc()).thenAnswer((_) => Future.value());
  });

  void setupDependencyInjection() {
    final getIt = GetIt.instance;
    getIt.registerSingleton<RealUnitRegistrationService>(MockDfxRegistrationService());
    getIt.registerSingleton<DfxCountryService>(MockDfxCountryService());
  }

  setUpAll(() {
    setupDependencyInjection();
  });

  tearDownAll(() async => await GetIt.instance.reset());

  Widget buildSubject(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: kycCubit),
        BlocProvider.value(value: registrationStepCubit),
        BlocProvider.value(value: registrationSubmitCubit),
      ],
      child: child,
    );
  }

  group('$RegistrationPage', () {
    testWidgets('renders $RegistrationView', (tester) async {
      await tester.pumpApp(const RegistrationPage());

      expect(find.byType(RegistrationView), findsOne);
    });
  });

  group('$RegistrationView', () {
    testWidgets('renders $RegistrationEmailStep', (tester) async {
      final state = const RegistrationStepState(
        step: RegistrationStep.email,
        steps: [
          RegistrationStep.email,
          RegistrationStep.personal,
          RegistrationStep.address,
        ],
      );
      when(() => registrationStepCubit.state).thenReturn(state);

      await tester.pumpApp(buildSubject(const RegistrationView()));

      (tester.widget(find.byType(PageView)) as PageView).controller?.jumpToPage(state.index);
      await tester.pump();

      expect(
        (tester.widget(find.byType(LinearProgressIndicator)) as LinearProgressIndicator).value,
        state.progress,
      );
      expect(find.byType(RegistrationEmailStep).hitTestable(), findsOne);
    });

    testWidgets('renders $RegistrationPersonalStep', (tester) async {
      final state = const RegistrationStepState(
        step: RegistrationStep.personal,
        steps: [RegistrationStep.email, RegistrationStep.personal, RegistrationStep.address],
      );
      when(() => registrationStepCubit.state).thenReturn(state);

      await tester.pumpApp(buildSubject(const RegistrationView()));

      (tester.widget(find.byType(PageView)) as PageView).controller?.jumpToPage(state.index);
      await tester.pump();

      expect(
        (tester.widget(find.byType(LinearProgressIndicator)) as LinearProgressIndicator).value,
        state.progress,
      );
      expect(find.byType(RegistrationPersonalStep).hitTestable(), findsOne);
    });

    testWidgets('renders $RegistrationAddressStep', (tester) async {
      final state = const RegistrationStepState(
        step: RegistrationStep.address,
        steps: [
          RegistrationStep.email,
          RegistrationStep.personal,
          RegistrationStep.address,
        ],
      );
      when(() => registrationStepCubit.state).thenReturn(state);

      await tester.pumpApp(buildSubject(const RegistrationView()));

      (tester.widget(find.byType(PageView)) as PageView).controller?.jumpToPage(state.index);
      await tester.pump();

      expect(
        (tester.widget(find.byType(LinearProgressIndicator)) as LinearProgressIndicator).value,
        state.progress,
      );
      expect(find.byType(RegistrationAddressStep), findsOne);
    });
  });

  group('$BlocListener', () {
    testWidgets('triggers checkKyc if submitting successes', (tester) async {
      whenListen(
        registrationSubmitCubit,
        Stream.fromIterable([
          const RegistrationSubmitSuccess(RegistrationStatus.completed),
        ]),
        initialState: RegistrationSubmitInitial(),
      );

      await tester.pumpApp(buildSubject(const RegistrationView()));
      await tester.pump();

      verify(() => kycCubit.checkKyc()).called(1);
    });

    testWidgets('shows SnackBar if submitting fails', (tester) async {
      whenListen(
        registrationSubmitCubit,
        Stream.fromIterable([const RegistrationSubmitFailure('fail')]),
        initialState: RegistrationSubmitInitial(),
      );

      await tester.pumpApp(buildSubject(const RegistrationView()));
      await tester.pump();

      expect(find.byType(SnackBar), findsOne);
    });
  });
}
