import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_status.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/cubits/registration_step/kyc_registration_step_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/cubits/registration_submit/kyc_registration_submit_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/kyc_registration_page.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/steps/kyc_registration_address_step.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/steps/kyc_registration_personal_step.dart';

import '../../../helper/helper.dart';

class MockRegistrationStepCubit extends MockCubit<KycRegistrationStepState>
    implements KycRegistrationStepCubit {}

class MockRegistrationSubmitCubit extends MockCubit<KycRegistrationSubmitState>
    implements KycRegistrationSubmitCubit {}

class MockKycCubit extends MockCubit<KycState> implements KycCubit {}

class MockRealUnitRegistrationService extends Mock implements RealUnitRegistrationService {}

class MockDfxCountryService extends Mock implements DfxCountryService {}

class MockDfxKycService extends Mock implements DfxKycService {}

void main() {
  late KycRegistrationStepCubit registrationStepCubit;
  late KycRegistrationSubmitCubit registrationSubmitCubit;
  late KycCubit kycCubit;

  setUp(() {
    registrationStepCubit = MockRegistrationStepCubit();
    registrationSubmitCubit = MockRegistrationSubmitCubit();
    kycCubit = MockKycCubit();

    when(() => registrationStepCubit.state).thenReturn(
      const KycRegistrationStepState(
        step: KycRegistrationStep.personal,
        steps: [
          KycRegistrationStep.personal,
          KycRegistrationStep.address,
        ],
      ),
    );
    when(() => registrationSubmitCubit.state).thenReturn(KycRegistrationSubmitInitial());
    when(() => kycCubit.state).thenReturn(const KycInitial());
    when(() => kycCubit.checkKyc()).thenAnswer((_) => Future.value());
    when(() => kycCubit.markRegistrationSignProduced()).thenReturn(null);
  });

  void setupDependencyInjection() {
    final getIt = GetIt.instance;
    getIt.registerSingleton<RealUnitRegistrationService>(MockRealUnitRegistrationService());
    getIt.registerSingleton<DfxCountryService>(MockDfxCountryService());
    getIt.registerSingleton<DfxKycService>(MockDfxKycService());
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

  group('$KycRegistrationPage', () {
    testWidgets('renders $KycRegistrationView', (tester) async {
      await tester.pumpApp(const KycRegistrationPage());

      expect(find.byType(KycRegistrationView), findsOne);
    });
  });

  group('$KycRegistrationView', () {
    testWidgets('renders $KycRegistrationPersonalStep', (tester) async {
      final state = const KycRegistrationStepState(
        step: KycRegistrationStep.personal,
        steps: [
          KycRegistrationStep.personal,
          KycRegistrationStep.address,
        ],
      );
      when(() => registrationStepCubit.state).thenReturn(state);

      await tester.pumpApp(buildSubject(const KycRegistrationView()));

      (tester.widget(find.byType(PageView)) as PageView).controller?.jumpToPage(state.index);
      await tester.pump();

      expect(find.byType(KycRegistrationPersonalStep).hitTestable(), findsOne);
    });

    testWidgets('renders $KycRegistrationAddressStep', (tester) async {
      final state = const KycRegistrationStepState(
        step: KycRegistrationStep.address,
        steps: [
          KycRegistrationStep.personal,
          KycRegistrationStep.address,
        ],
      );
      when(() => registrationStepCubit.state).thenReturn(state);

      await tester.pumpApp(buildSubject(const KycRegistrationView()));

      (tester.widget(find.byType(PageView)) as PageView).controller?.jumpToPage(state.index);
      await tester.pump();

      expect(find.byType(KycRegistrationAddressStep), findsOne);
    });
  });

  group('$BlocListener', () {
    testWidgets('triggers checkKyc if submitting successes', (tester) async {
      whenListen(
        registrationSubmitCubit,
        Stream.fromIterable([
          const KycRegistrationSubmitSuccess(RegistrationStatus.completed),
        ]),
        initialState: KycRegistrationSubmitInitial(),
      );

      await tester.pumpApp(buildSubject(const KycRegistrationView()));
      await tester.pump();

      verify(() => kycCubit.markRegistrationSignProduced()).called(1);
      verify(() => kycCubit.checkKyc()).called(1);
    });

    testWidgets(
      'marks sign produced + triggers checkKyc on Success(alreadyRegistered)',
      (tester) async {
        // Wave 3.2 regression guard: the API now emits a structured
        // `Success(alreadyRegistered)` instead of a swallowed
        // ApiException, and the listener must treat it identically to
        // `completed` — the EIP-712 sign has already happened, so the
        // sign gate must be lifted and the KYC step refreshed.
        whenListen(
          registrationSubmitCubit,
          Stream.fromIterable([
            const KycRegistrationSubmitSuccess(RegistrationStatus.alreadyRegistered),
          ]),
          initialState: KycRegistrationSubmitInitial(),
        );

        await tester.pumpApp(buildSubject(const KycRegistrationView()));
        await tester.pump();

        verify(() => kycCubit.markRegistrationSignProduced()).called(1);
        verify(() => kycCubit.checkKyc()).called(1);
      },
    );

    testWidgets(
      'marks sign produced + triggers checkKyc on Success(pendingReview)',
      (tester) async {
        whenListen(
          registrationSubmitCubit,
          Stream.fromIterable([
            const KycRegistrationSubmitSuccess(RegistrationStatus.pendingReview),
          ]),
          initialState: KycRegistrationSubmitInitial(),
        );

        await tester.pumpApp(buildSubject(const KycRegistrationView()));
        await tester.pump();

        verify(() => kycCubit.markRegistrationSignProduced()).called(1);
        verify(() => kycCubit.checkKyc()).called(1);
      },
    );

    testWidgets(
      'shows SnackBar AND lifts the sign gate on Success(forwardingFailed)',
      (tester) async {
        whenListen(
          registrationSubmitCubit,
          Stream.fromIterable([
            const KycRegistrationSubmitSuccess(RegistrationStatus.forwardingFailed),
          ]),
          initialState: KycRegistrationSubmitInitial(),
        );

        await tester.pumpApp(buildSubject(const KycRegistrationView()));
        await tester.pump();

        verify(() => kycCubit.markRegistrationSignProduced()).called(1);
        verify(() => kycCubit.checkKyc()).called(1);
        expect(find.byType(SnackBar), findsOne);
      },
    );

    testWidgets('shows SnackBar if submitting fails', (tester) async {
      whenListen(
        registrationSubmitCubit,
        Stream.fromIterable([const KycRegistrationSubmitFailure('fail')]),
        initialState: KycRegistrationSubmitInitial(),
      );

      await tester.pumpApp(buildSubject(const KycRegistrationView()));
      await tester.pump();

      expect(find.byType(SnackBar), findsOne);
    });
  });
}
