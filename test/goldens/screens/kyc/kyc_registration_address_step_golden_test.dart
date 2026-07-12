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

import '../../../helper/helper.dart';

class _MockKycRegistrationStepCubit extends MockCubit<KycRegistrationStepState>
    implements KycRegistrationStepCubit {}

void main() {
  late _MockKycRegistrationStepCubit stepCubit;

  setUpAll(() {
    GetIt.instance.registerSingleton<DfxCountryService>(fixtureCountryService());
  });

  tearDownAll(() async => GetIt.instance.reset());

  setUp(() {
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

  Widget buildSubject() => wrapForGolden(
        BlocProvider<KycRegistrationStepCubit>.value(
          value: stepCubit,
          child: Scaffold(
            body: KycRegistrationAddressStep(
              addressStreetCtrl: TextEditingController(),
              addressNumberCtrl: TextEditingController(),
              postalCodeCtrl: TextEditingController(),
              cityCtrl: TextEditingController(),
              countryCtrl: ValueNotifier<Country?>(null),
            ),
          ),
        ),
      );

  // Tap the residence country field open so the selectable country list is
  // captured (CH/DE/IT/FR float to the top by CountryField's priority sort).
  Future<void> openCountryDropdown(WidgetTester tester) async {
    await tester.pumpAndSettle();
    final field = find.byType(DropdownButtonFormField<Country>);
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.tap(field);
    await tester.pumpAndSettle();
  }

  group('$KycRegistrationAddressStep', () {
    goldenTest(
      'empty address form',
      fileName: 'kyc_registration_address_step_default',
      constraints: phoneConstraints,
      builder: buildSubject,
    );

    goldenTest(
      'residence country dropdown open — the selectable country list',
      fileName: 'kyc_registration_address_step_dropdown_open',
      constraints: phoneConstraints,
      pumpBeforeTest: openCountryDropdown,
      builder: buildSubject,
    );
  });
}
