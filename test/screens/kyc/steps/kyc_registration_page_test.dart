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
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/kyc/kyc_personal_data.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_user_type.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/real_unit_user_data_dto.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

import '../../../helper/helper.dart';

const _countryCH = Country(id: 41, symbol: 'CH', name: 'Switzerland', kycAllowed: true);
const _countryDE = Country(id: 42, symbol: 'DE', name: 'Germany', kycAllowed: true);

RealUnitUserDataDto _userData(String addressCountry) => RealUnitUserDataDto(
      email: 'ada@example.com',
      name: 'Ada Lovelace',
      type: 'HUMAN',
      phoneNumber: '+41790000000',
      birthday: '1990-05-15',
      nationality: 'CH',
      addressStreet: 'S',
      addressPostalCode: '8000',
      addressCity: 'Zurich',
      addressCountry: addressCountry,
      swissTaxResidence: true,
      lang: 'de',
      kycData: const KycPersonalData(
        accountType: KycAccountType.personal,
        firstName: 'Ada',
        lastName: 'Lovelace',
        phone: '+41790000000',
        address: KycAddress(street: 'S', houseNumber: '13', zip: '8000', city: 'Zurich', country: 41),
      ),
    );

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
  late MockDfxCountryService countryService;

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
    countryService = MockDfxCountryService();
    getIt.registerSingleton<DfxCountryService>(countryService);
    getIt.registerSingleton<DfxKycService>(MockDfxKycService());
  }

  setUpAll(() {
    setupDependencyInjection();
    registerFallbackValue(_countryCH);
    registerFallbackValue(RegistrationUserType.human);
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

  group('swissTaxResidence (issue #657 P5 F6)', () {
    Future<bool> submittedSwissTaxResidenceFor(
      WidgetTester tester,
      String addressCountrySymbol,
    ) async {
      when(() => registrationStepCubit.state).thenReturn(
        const KycRegistrationStepState(
          step: KycRegistrationStep.address,
          steps: [KycRegistrationStep.personal, KycRegistrationStep.address],
        ),
      );
      when(() => countryService.getAllCountries()).thenAnswer((_) async => [_countryCH, _countryDE]);
      when(() => countryService.getCountryBySymbol('CH')).thenAnswer((_) async => _countryCH);
      when(() => countryService.getCountryBySymbol('DE')).thenAnswer((_) async => _countryDE);
      when(() => registrationSubmitCubit.submit(
            type: any(named: 'type'),
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
            phoneNumber: any(named: 'phoneNumber'),
            birthday: any(named: 'birthday'),
            nationality: any(named: 'nationality'),
            addressStreet: any(named: 'addressStreet'),
            addressStreetNumber: any(named: 'addressStreetNumber'),
            addressPostalCode: any(named: 'addressPostalCode'),
            addressCity: any(named: 'addressCity'),
            addressCountry: any(named: 'addressCountry'),
            swissTaxResidence: any(named: 'swissTaxResidence'),
          )).thenAnswer((_) async {});

      await tester.pumpApp(
        buildSubject(KycRegistrationView(initialUserData: _userData(addressCountrySymbol))),
      );
      // Let the async country lookups (_resolveInitialCountries) resolve so the
      // country fields are populated before submit.
      await tester.pumpAndSettle();

      (tester.widget(find.byType(PageView)) as PageView).controller?.jumpToPage(1);
      await tester.pumpAndSettle();

      final completeButton = find.descendant(
        of: find.byType(KycRegistrationAddressStep),
        matching: find.byType(AppFilledButton),
      );
      await tester.ensureVisible(completeButton);
      await tester.pumpAndSettle();
      await tester.tap(completeButton);
      await tester.pump();

      final captured = verify(() => registrationSubmitCubit.submit(
            type: any(named: 'type'),
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
            phoneNumber: any(named: 'phoneNumber'),
            birthday: any(named: 'birthday'),
            nationality: any(named: 'nationality'),
            addressStreet: any(named: 'addressStreet'),
            addressStreetNumber: any(named: 'addressStreetNumber'),
            addressPostalCode: any(named: 'addressPostalCode'),
            addressCity: any(named: 'addressCity'),
            addressCountry: any(named: 'addressCountry'),
            swissTaxResidence: captureAny(named: 'swissTaxResidence'),
          )).captured;
      return captured.single as bool;
    }

    testWidgets('is true when the residence country is Switzerland', (tester) async {
      expect(await submittedSwissTaxResidenceFor(tester, 'CH'), isTrue);
    });

    testWidgets('is false for a non-Swiss residence country (was hardcoded true)',
        (tester) async {
      expect(await submittedSwissTaxResidenceFor(tester, 'DE'), isFalse);
    });
  });
}
