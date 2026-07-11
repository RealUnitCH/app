import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/cubits/registration_step/kyc_registration_step_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/steps/kyc_registration_address_step.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

import '../../../../../helper/pump_app.dart';

class _MockDfxCountryService extends Mock implements DfxCountryService {}

class _MockKycRegistrationStepCubit extends MockCubit<KycRegistrationStepState>
    implements KycRegistrationStepCubit {}

const _germany = Country(id: 49, symbol: 'DE', name: 'Germany', kycAllowed: true);
const _switzerland = Country(id: 41, symbol: 'CH', name: 'Switzerland', kycAllowed: true);

void main() {
  late _MockDfxCountryService countryService;
  late _MockKycRegistrationStepCubit stepCubit;

  setUp(() {
    countryService = _MockDfxCountryService();
    when(() => countryService.getAllCountries())
        .thenAnswer((_) async => <Country>[_switzerland, _germany]);
    GetIt.instance.registerSingleton<DfxCountryService>(countryService);

    stepCubit = _MockKycRegistrationStepCubit();
    when(() => stepCubit.state).thenReturn(
      const KycRegistrationStepState(
        step: KycRegistrationStep.address,
        steps: [
          KycRegistrationStep.personal,
          KycRegistrationStep.address,
          KycRegistrationStep.taxResidence,
        ],
      ),
    );
  });

  tearDown(() async => GetIt.instance.reset());

  // Prefill the free-text fields with valid Swiss-payment-text values so the
  // only outstanding validation gate is the residence country selection.
  Future<_Harness> pump(WidgetTester tester) async {
    final harness = _Harness();

    await tester.pumpApp(
      BlocProvider<KycRegistrationStepCubit>.value(
        value: stepCubit,
        child: Scaffold(
          body: KycRegistrationAddressStep(
            addressStreetCtrl: harness.addressStreetCtrl,
            addressNumberCtrl: harness.addressNumberCtrl,
            postalCodeCtrl: harness.postalCodeCtrl,
            cityCtrl: harness.cityCtrl,
            countryCtrl: harness.countryCtrl,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return harness;
  }

  Finder scrollable() => find.byType(Scrollable).first;

  Future<void> selectResidenceCountry(WidgetTester tester) async {
    final dropdown = find.byType(DropdownButtonFormField<Country>);
    await tester.scrollUntilVisible(dropdown, 100, scrollable: scrollable());
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Switzerland').last);
    await tester.pumpAndSettle();
  }

  Future<void> tapContinue(WidgetTester tester) async {
    final button = find.byType(AppFilledButton);
    await tester.scrollUntilVisible(button, 100, scrollable: scrollable());
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  group('$KycRegistrationAddressStep', () {
    testWidgets('renders the address fields and a continue button', (tester) async {
      await pump(tester);

      expect(find.byType(DropdownButtonFormField<Country>), findsOneWidget);
      expect(find.byType(AppFilledButton), findsOneWidget);
    });

    testWidgets(
      'advances to the next step once the form is valid',
      (tester) async {
        await pump(tester);
        await selectResidenceCountry(tester);

        await tapContinue(tester);

        verify(() => stepCubit.next()).called(1);
      },
    );

    testWidgets(
      'does not advance while the form is invalid (no country picked)',
      (tester) async {
        await pump(tester);

        // No residence country selected → CountryField keeps the form invalid.
        await tapContinue(tester);

        verifyNever(() => stepCubit.next());
      },
    );
  });
}

class _Harness {
  final addressStreetCtrl = TextEditingController(text: 'Bahnhofstrasse');
  final addressNumberCtrl = TextEditingController(text: '1');
  final postalCodeCtrl = TextEditingController(text: '8000');
  final cityCtrl = TextEditingController(text: 'Zurich');
  final countryCtrl = ValueNotifier<Country?>(null);
}
