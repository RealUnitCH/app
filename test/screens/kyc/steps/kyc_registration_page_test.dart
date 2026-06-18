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
import 'package:realunit_wallet/widgets/form/labeled_text_field.dart';

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
  });

  // The page no longer reads from `RealUnitRegistrationService` directly — the parent
  // `KycCubit` propagates the `RealUnitUserDataDto` via constructor. We still
  // need the country/kyc/registration services for the BlocProvider inside
  // `KycRegistrationPage` (they are looked up via `getIt`).
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
    testWidgets('renders $KycRegistrationView with null initialUserData', (tester) async {
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
      // No prefill round-trip: the form is rendered synchronously. A single
      // pump is enough to settle initial frames.
      await tester.pump();

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
      await tester.pump();

      (tester.widget(find.byType(PageView)) as PageView).controller?.jumpToPage(state.index);
      await tester.pump();

      expect(find.byType(KycRegistrationAddressStep), findsOne);
    });

    testWidgets('postal code field uses a text keyboard for alphanumeric codes',
        (tester) async {
      // Regression guard: foreign postal codes are alphanumeric (NL "1011 AB",
      // UK "EC1A 1BB"). A number-only keyboard blocked customers from entering
      // them even though the validator + backend accept letters and spaces.
      final state = const KycRegistrationStepState(
        step: KycRegistrationStep.address,
        steps: [
          KycRegistrationStep.personal,
          KycRegistrationStep.address,
        ],
      );
      when(() => registrationStepCubit.state).thenReturn(state);

      await tester.pumpApp(buildSubject(const KycRegistrationView()));
      await tester.pump();

      (tester.widget(find.byType(PageView)) as PageView).controller?.jumpToPage(state.index);
      await tester.pump();

      final postalField = tester.widget<LabeledTextField>(
        find.byWidgetPredicate((w) => w is LabeledTextField && w.hintText == '8000'),
      );
      expect(postalField.keyboardType, TextInputType.text);
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

      verify(() => kycCubit.checkKyc()).called(1);
    });

    testWidgets(
      'triggers checkKyc on Success(alreadyRegistered)',
      (tester) async {
        // Wave 3.2 regression guard: the API now emits a structured
        // `Success(alreadyRegistered)` instead of a swallowed
        // ApiException, and the listener must treat it identically to
        // `completed` — call `checkKyc` so the cubit re-fetches the
        // server-side registration state and dispatches the next step.
        whenListen(
          registrationSubmitCubit,
          Stream.fromIterable([
            const KycRegistrationSubmitSuccess(RegistrationStatus.alreadyRegistered),
          ]),
          initialState: KycRegistrationSubmitInitial(),
        );

        await tester.pumpApp(buildSubject(const KycRegistrationView()));
        await tester.pump();

        verify(() => kycCubit.checkKyc()).called(1);
      },
    );

    testWidgets(
      'triggers checkKyc on Success(pendingReview)',
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

        verify(() => kycCubit.checkKyc()).called(1);
      },
    );

    testWidgets(
      'shows SnackBar AND triggers checkKyc on Success(forwardingFailed)',
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
