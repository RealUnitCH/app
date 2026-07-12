import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/steps/kyc_registration_tax_step.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

import '../../../helper/helper.dart';

void main() {
  setUpAll(() {
    GetIt.instance.registerSingleton<DfxCountryService>(fixtureCountryService());
  });

  tearDownAll(() async => GetIt.instance.reset());

  Widget buildSubject() => wrapForGolden(
        Scaffold(
          body: KycRegistrationTaxStep(
            taxCountryCtrl: ValueNotifier<Country?>(null),
            tinCtrl: TextEditingController(),
            onSubmit: () async {},
          ),
        ),
      );

  Future<void> selectCountry(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<Country>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  Future<void> tapComplete(WidgetTester tester) async {
    await tester.tap(find.byType(AppFilledButton));
    await tester.pumpAndSettle();
  }

  group('$KycRegistrationTaxStep', () {
    goldenTest(
      'empty — nothing picked, no TIN',
      fileName: 'kyc_registration_tax_step_default',
      constraints: phoneConstraints,
      builder: buildSubject,
    );

    goldenTest(
      'Swiss tax residence — no TIN',
      fileName: 'kyc_registration_tax_step_swiss',
      constraints: phoneConstraints,
      pumpBeforeTest: (tester) => selectCountry(tester, 'Switzerland'),
      builder: buildSubject,
    );

    goldenTest(
      'non-Swiss tax residence — TIN revealed',
      fileName: 'kyc_registration_tax_step_non_swiss',
      constraints: phoneConstraints,
      pumpBeforeTest: (tester) => selectCountry(tester, 'Germany'),
      builder: buildSubject,
    );

    goldenTest(
      'validation error — no tax-residence country picked',
      fileName: 'kyc_registration_tax_step_country_error',
      constraints: phoneConstraints,
      pumpBeforeTest: (tester) async {
        await tester.pumpAndSettle();
        await tapComplete(tester);
      },
      builder: buildSubject,
    );

    goldenTest(
      'validation error — non-Swiss residence with an empty TIN',
      fileName: 'kyc_registration_tax_step_tin_error',
      constraints: phoneConstraints,
      pumpBeforeTest: (tester) async {
        await selectCountry(tester, 'Germany');
        await tapComplete(tester);
      },
      builder: buildSubject,
    );
  });
}
