import 'package:bitbox_flutter/bitbox_flutter.dart' as sdk;
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dto/real_unit_registration_request_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/kyc/kyc_personal_data.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_status.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_user_type.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/real_unit_user_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/exceptions/signing_cancelled_exception.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/connect_bitbox_page.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/cubits/registration_step/kyc_registration_step_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/cubits/registration_submit/kyc_registration_submit_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/kyc_registration_page.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/steps/kyc_registration_address_step.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/steps/kyc_registration_personal_step.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/form/country_field.dart';
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

class MockHomeBloc extends MockBloc<HomeEvent, HomeState> implements HomeBloc {}

class MockAppStore extends Mock implements AppStore {}

class MockAWallet extends Mock implements AWallet {}

class MockWalletService extends Mock implements WalletService {}

class MockBitboxService extends Mock implements BitboxService {}

// Historical placeholder already used as the registration fixture in
// test/screens/kyc/cubits/kyc/kyc_cubit_test.dart — reused here for consistency.
const _country = Country(id: 41, symbol: 'CH', name: 'Switzerland', kycAllowed: true);

const _kycPersonalData = KycPersonalData(
  accountType: KycAccountType.personal,
  firstName: 'Ada',
  lastName: 'Lovelace',
  phone: '+41790000000',
  address: KycAddress(street: 'S', zip: '8000', city: 'Zurich', country: 41),
);

const _fixtureUserData = RealUnitUserDataDto(
  email: 'ada@example.com',
  name: 'Ada Lovelace',
  type: 'HUMAN',
  phoneNumber: '+41790000000',
  birthday: '1815-12-10',
  nationality: 'CH',
  addressStreet: 'S',
  addressPostalCode: '8000',
  addressCity: 'Zurich',
  addressCountry: 'CH',
  swissTaxResidence: true,
  lang: 'de',
  kycData: _kycPersonalData,
);

const _registrationFixture = Registration(
  type: RegistrationUserType.human,
  email: 'ada@example.com',
  firstName: 'Ada',
  lastName: 'Lovelace',
  phoneNumber: '+41790000000',
  birthday: '1815-12-10',
  nationality: _country,
  addressStreet: 'S',
  addressStreetNumber: '1',
  addressPostalCode: '8000',
  addressCity: 'Zurich',
  addressCountry: _country,
  swissTaxResidence: true,
);

const _switzerland = Country(id: 41, symbol: 'CH', name: 'Switzerland', kycAllowed: true);
const _germany = Country(id: 49, symbol: 'DE', name: 'Germany', kycAllowed: true);

void main() {
  late KycRegistrationStepCubit registrationStepCubit;
  late KycRegistrationSubmitCubit registrationSubmitCubit;
  late KycCubit kycCubit;
  late HomeBloc homeBloc;

  setUp(() {
    registrationStepCubit = MockRegistrationStepCubit();
    registrationSubmitCubit = MockRegistrationSubmitCubit();
    kycCubit = MockKycCubit();
    homeBloc = MockHomeBloc();

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
    final appStore = MockAppStore();
    when(() => appStore.wallet).thenReturn(MockAWallet());
    getIt.registerSingleton<AppStore>(appStore);
    // The BitBox submit branch opens ConnectBitboxPage, which resolves a
    // BitboxService + WalletService from getIt on build. Stub the scan surface
    // so the page renders without a real device (no pairing is exercised here).
    final bitboxService = MockBitboxService();
    when(() => bitboxService.startScan()).thenAnswer((_) async => false);
    when(() => bitboxService.getAllUsbDevices()).thenAnswer((_) async => <sdk.BitboxDevice>[]);
    getIt.registerSingleton<BitboxService>(bitboxService);
    getIt.registerSingleton<WalletService>(MockWalletService());
  }

  setUpAll(() {
    registerFallbackValue(SyncWalletServicesEvent(MockAWallet()));
    registerFallbackValue(_registrationFixture);
    registerFallbackValue(_switzerland);
    registerFallbackValue(RegistrationUserType.human);
    setupDependencyInjection();
  });

  tearDownAll(() async => await GetIt.instance.reset());

  Widget buildSubject(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: kycCubit),
        BlocProvider.value(value: registrationStepCubit),
        BlocProvider.value(value: registrationSubmitCubit),
        BlocProvider.value(value: homeBloc),
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

    testWidgets('dismisses the keyboard when tapping outside the address fields',
        (tester) async {
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

      // Focus the street field so there is a primary focus to clear.
      final streetField = find
          .descendant(
            of: find.byType(KycRegistrationAddressStep),
            matching: find.byType(EditableText),
          )
          .first;
      final streetFocus = tester.widget<EditableText>(streetField).focusNode;
      await tester.tap(streetField);
      await tester.pump();
      expect(streetFocus.hasFocus, isTrue);

      // The opaque GestureDetector wrapping the form clears focus on tap — it is
      // the only opaque GestureDetector that is an ancestor of the address Form
      // (field/button gesture handlers are descendants of the Form).
      final dismissArea = find.ancestor(
        of: find.descendant(
          of: find.byType(KycRegistrationAddressStep),
          matching: find.byType(Form),
        ),
        matching: find.byWidgetPredicate(
          (w) => w is GestureDetector && w.behavior == HitTestBehavior.opaque && w.onTap != null,
        ),
      );
      expect(dismissArea, findsOneWidget);
      tester.widget<GestureDetector>(dismissArea).onTap!();
      await tester.pump();

      expect(streetFocus.hasFocus, isFalse);
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

    testWidgets('re-arms wallet services on registration success', (tester) async {
      // The RealUnit account now exists, so the balance poll (which stops
      // itself after 404ing while the account was missing) must be restarted.
      whenListen(
        registrationSubmitCubit,
        Stream.fromIterable([
          const KycRegistrationSubmitSuccess(RegistrationStatus.completed),
        ]),
        initialState: KycRegistrationSubmitInitial(),
      );

      await tester.pumpApp(buildSubject(const KycRegistrationView()));
      await tester.pump();

      verify(() => homeBloc.add(any(that: isA<SyncWalletServicesEvent>()))).called(1);
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
        // The re-arm fires for every success status, not just `completed` —
        // `forwardingFailed` still means the account was accepted.
        verify(() => homeBloc.add(any(that: isA<SyncWalletServicesEvent>()))).called(1);
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
      // A failed submit must not re-arm the wallet services — the re-arm is
      // gated behind KycRegistrationSubmitSuccess.
      verifyNever(() => homeBloc.add(any(that: isA<SyncWalletServicesEvent>())));
    });
  });

  group('$KycRegistrationPage prefill', () {
    testWidgets('seeds the form fields from initialUserData', (tester) async {
      final countryService = GetIt.instance.get<DfxCountryService>() as MockDfxCountryService;
      when(() => countryService.getCountryBySymbol(any())).thenAnswer((_) async => _country);

      await tester.pumpApp(const KycRegistrationPage(initialUserData: _fixtureUserData));
      // Scalars seed synchronously in initState; the two country lookups resolve
      // via DfxCountryService and setState on completion.
      await tester.pumpAndSettle();

      expect(find.text('Ada'), findsOneWidget);
      expect(find.text('Lovelace'), findsOneWidget);
      // nationality + addressCountry both resolve through the country service.
      verify(() => countryService.getCountryBySymbol('CH')).called(2);
    });

    testWidgets('degrades gracefully when the country lookup fails', (tester) async {
      final countryService = GetIt.instance.get<DfxCountryService>() as MockDfxCountryService;
      when(() => countryService.getCountryBySymbol(any()))
          .thenAnswer((_) async => throw Exception('unknown symbol'));

      await tester.pumpApp(const KycRegistrationPage(initialUserData: _fixtureUserData));
      await tester.pumpAndSettle();

      // The scalar prefill still applies. The lookup failure is swallowed by
      // _resolveInitialCountries' catch, so it never escapes as an unhandled
      // async error — takeException() stays null (the country fields fall back
      // to empty / their own load-failed state, which is not asserted here).
      expect(find.text('Ada'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('$KycRegistrationView page transitions', () {
    testWidgets('animates to the step emitted by the step cubit', (tester) async {
      const personal = KycRegistrationStepState(
        step: KycRegistrationStep.personal,
        steps: [KycRegistrationStep.personal, KycRegistrationStep.address],
      );
      const address = KycRegistrationStepState(
        step: KycRegistrationStep.address,
        steps: [KycRegistrationStep.personal, KycRegistrationStep.address],
      );
      whenListen(
        registrationStepCubit,
        Stream.fromIterable([address]),
        initialState: personal,
      );

      await tester.pumpApp(buildSubject(const KycRegistrationView()));
      // The initState subscription drives _pageController.animateToPage on the
      // emitted step, landing the address page.
      await tester.pumpAndSettle();

      expect(find.byType(KycRegistrationAddressStep).hitTestable(), findsOneWidget);
    });
  });

  group('$KycRegistrationView submit feedback', () {
    testWidgets(
      'shows the signing-cancelled message when the failure cause is a '
      'SigningCancelledException',
      (tester) async {
        whenListen(
          registrationSubmitCubit,
          Stream.fromIterable([
            const KycRegistrationSubmitFailure('cancelled', cause: SigningCancelledException()),
          ]),
          initialState: KycRegistrationSubmitInitial(),
        );

        await tester.pumpApp(buildSubject(const KycRegistrationView()));
        await tester.pump();

        expect(find.byType(SnackBar), findsOne);
        expect(find.textContaining('Signature cancelled'), findsOneWidget);
      },
    );

    testWidgets('shows the loading overlay while a submit is in flight', (tester) async {
      whenListen(
        registrationSubmitCubit,
        Stream.fromIterable([KycRegistrationSubmitLoading()]),
        initialState: KycRegistrationSubmitInitial(),
      );

      await tester.pumpApp(buildSubject(const KycRegistrationView()));
      await tester.pump();

      // Target the overlay specifically: the personal step's CountryField also
      // renders a CupertinoActivityIndicator while its country list loads, so
      // byType alone is not unique. The overlay is the white Container layered
      // over the PageView (kyc_registration_page.dart:229-234).
      final overlay = find.byWidgetPredicate(
        (w) => w is Container && w.color == RealUnitColors.basic.white,
      );
      expect(
        find.descendant(of: overlay, matching: find.byType(CupertinoActivityIndicator)),
        findsOneWidget,
      );
    });
  });

  group('$KycRegistrationView BitBox submit', () {
    testWidgets(
      'opens the ConnectBitbox sheet and retries submit once pairing finishes',
      (tester) async {
        when(() => registrationSubmitCubit.retrySubmit(any())).thenAnswer((_) async {});
        whenListen(
          registrationSubmitCubit,
          Stream.fromIterable([
            const KycRegistrationSubmitBitboxRequired(registration: _registrationFixture),
          ]),
          initialState: KycRegistrationSubmitInitial(),
        );

        // The sheet callback calls context.pop(true); that needs a GoRouter in
        // scope, which pumpApp's MaterialApp.home does not provide.
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => buildSubject(const KycRegistrationView()),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
          ),
        );
        // Let the BlocListener open the modal bottom sheet and settle it in.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Drive the sheet's onFinish exactly as ConnectBitboxView would on a
        // successful pairing, without exercising the pairing ceremony itself.
        final page = tester.widget<ConnectBitboxPage>(find.byType(ConnectBitboxPage));
        page.onFinish(MockAWallet());
        await tester.pump();
        // Let the popped sheet's future resolve and the route tear down (which
        // closes the real ConnectBitboxCubit and cancels its scan timer).
        await tester.pump(const Duration(milliseconds: 500));

        verify(() => homeBloc.add(any(that: isA<SyncWalletServicesEvent>()))).called(1);
        verify(() => registrationSubmitCubit.retrySubmit(_registrationFixture)).called(1);
      },
    );
  });

  // End-to-end wiring of the tax-residence branch: driving the real address
  // form (prefilled Swiss address) and submitting must forward the
  // controller-derived `swissTaxResidence` + `countryAndTINs` into the submit
  // cubit. Covers both arms of `_onSubmit` on the page.
  group('$KycRegistrationView tax residence submit wiring', () {
    const initialUserData = RealUnitUserDataDto(
      email: 'a@b.com',
      name: 'Ada Lovelace',
      type: 'HUMAN',
      phoneNumber: '+41 79 000 00 00',
      birthday: '1815-12-10',
      nationality: 'CH',
      addressStreet: 'Bahnhofstrasse 1',
      addressPostalCode: '8000',
      addressCity: 'Zurich',
      addressCountry: 'CH',
      swissTaxResidence: true,
      lang: 'de',
      kycData: KycPersonalData(
        accountType: KycAccountType.personal,
        firstName: 'Ada',
        lastName: 'Lovelace',
        phone: '+41 79 000 00 00',
        address: KycAddress(
          street: 'Bahnhofstrasse',
          houseNumber: '1',
          zip: '8000',
          city: 'Zurich',
          country: 41,
        ),
      ),
    );

    setUp(() {
      // Land the pager on the address step so the tax-residence section is in
      // view once we jump the PageView to it.
      when(() => registrationStepCubit.state).thenReturn(
        const KycRegistrationStepState(
          step: KycRegistrationStep.address,
          steps: [
            KycRegistrationStep.personal,
            KycRegistrationStep.address,
          ],
        ),
      );

      final countryService =
          GetIt.instance<DfxCountryService>() as MockDfxCountryService;
      when(() => countryService.getAllCountries())
          .thenAnswer((_) async => <Country>[_switzerland, _germany]);
      when(() => countryService.getCountryBySymbol(any()))
          .thenAnswer((_) async => _switzerland);

      when(
        () => registrationSubmitCubit.submit(
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
          countryAndTINs: any(named: 'countryAndTINs'),
        ),
      ).thenAnswer((_) async {});
    });

    Finder addressScrollable() => find
        .descendant(
          of: find.byType(KycRegistrationAddressStep),
          matching: find.byType(Scrollable),
        )
        .first;

    Future<void> showAddressStep(WidgetTester tester) async {
      await tester.pumpApp(
        buildSubject(const KycRegistrationView(initialUserData: initialUserData)),
      );
      // Let the seeded country lookups resolve before the address page mounts.
      await tester.pumpAndSettle();

      final index = registrationStepCubit.state.index;
      (tester.widget(find.byType(PageView)) as PageView).controller?.jumpToPage(index);
      await tester.pumpAndSettle();
    }

    Future<void> selectResidenceCountry(WidgetTester tester) async {
      // Before the toggle flips, the address step hosts a single country
      // dropdown (residence). Selecting a value makes the form validatable
      // regardless of any initial-value seeding timing.
      final residenceDropdown = find.descendant(
        of: find.byType(KycRegistrationAddressStep),
        matching: find.byType(DropdownButtonFormField<Country>),
      );
      await tester.scrollUntilVisible(
        residenceDropdown,
        100,
        scrollable: addressScrollable(),
      );
      await tester.tap(residenceDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Switzerland').last);
      await tester.pumpAndSettle();
    }

    Future<void> tapComplete(WidgetTester tester) async {
      final completeButton = find.descendant(
        of: find.byType(KycRegistrationAddressStep),
        matching: find.byType(AppFilledButton),
      );
      await tester.scrollUntilVisible(
        completeButton,
        100,
        scrollable: addressScrollable(),
      );
      await tester.tap(completeButton);
      await tester.pumpAndSettle();
    }

    List<dynamic> captureSubmit() => verify(
      () => registrationSubmitCubit.submit(
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
        countryAndTINs: captureAny(named: 'countryAndTINs'),
      ),
    ).captured;

    testWidgets(
      'default Swiss-only submit forwards swissTaxResidence:true and null countryAndTINs',
      (tester) async {
        await showAddressStep(tester);
        await selectResidenceCountry(tester);

        // The toggle stays on (Swiss-only) — no tax fields appear.
        await tapComplete(tester);

        final captured = captureSubmit();
        expect(captured[0], isTrue);
        expect(captured[1], isNull);
      },
    );

    testWidgets(
      'non-Swiss submit forwards swissTaxResidence:false and a countryAndTINs entry',
      (tester) async {
        await showAddressStep(tester);
        await selectResidenceCountry(tester);

        // Flip Swiss-only off to reveal the tax-residence country + TIN.
        final toggle = find.descendant(
          of: find.byType(KycRegistrationAddressStep),
          matching: find.byType(Switch),
        );
        await tester.scrollUntilVisible(toggle, 100, scrollable: addressScrollable());
        await tester.tap(toggle);
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(KycRegistrationAddressStep));

        final taxDropdown = find.descendant(
          of: find.ancestor(
            of: find.text(S.of(context).taxResidenceCountry),
            matching: find.byType(CountryField),
          ),
          matching: find.byType(DropdownButtonFormField<Country>),
        );
        await tester.scrollUntilVisible(taxDropdown, 100, scrollable: addressScrollable());
        await tester.tap(taxDropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Germany').last);
        await tester.pumpAndSettle();

        final tinField = find.widgetWithText(TextFormField, S.of(context).tinHint);
        await tester.scrollUntilVisible(tinField, 100, scrollable: addressScrollable());
        // Enter with surrounding whitespace: _onSubmit must trim it before
        // forwarding, so the captured TIN is the trimmed value.
        await tester.enterText(tinField, '  12 345 678 901  ');
        await tester.pump();

        await tapComplete(tester);

        final captured = captureSubmit();
        expect(captured[0], isFalse);
        final tins = captured[1] as List<CountryAndTin>;
        expect(tins, hasLength(1));
        expect(tins.single.country, 'DE');
        expect(tins.single.tin, '12 345 678 901');
      },
    );
  });
}
