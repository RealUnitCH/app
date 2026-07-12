import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_user_type.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/cubits/registration_step/kyc_registration_step_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/steps/kyc_registration_personal_step.dart';

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
        step: KycRegistrationStep.personal,
        steps: [
          KycRegistrationStep.personal,
          KycRegistrationStep.address,
        ],
      ),
    );
  });

  Widget buildSubject() => wrapForGolden(
        BlocProvider<KycRegistrationStepCubit>.value(
          value: stepCubit,
          child: Scaffold(
            body: KycRegistrationPersonalStep(
              typeCtrl: ValueNotifier<RegistrationUserType>(
                RegistrationUserType.human,
              ),
              firstNameCtrl: TextEditingController(),
              lastNameCtrl: TextEditingController(),
              phoneCtrl: ValueNotifier<String?>(null),
              nationalityCtrl: ValueNotifier<Country?>(null),
              birthdayCtrl: ValueNotifier<String?>(null),
            ),
          ),
        ),
      );

  // Tap the nationality country field open so the selectable country list is
  // captured (CH/DE/IT/FR float to the top by CountryField's priority sort).
  Future<void> openCountryDropdown(WidgetTester tester) async {
    await tester.pumpAndSettle();
    final field = find.byType(DropdownButtonFormField<Country>);
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.tap(field);
    await tester.pumpAndSettle();
  }

  group('$KycRegistrationPersonalStep', () {
    goldenTest(
      'empty personal form',
      fileName: 'kyc_registration_personal_step_default',
      constraints: phoneConstraints,
      builder: buildSubject,
    );

    goldenTest(
      'nationality dropdown open — the selectable country list',
      fileName: 'kyc_registration_personal_step_dropdown_open',
      constraints: phoneConstraints,
      pumpBeforeTest: openCountryDropdown,
      builder: buildSubject,
    );
  });
}
