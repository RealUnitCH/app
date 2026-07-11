import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/steps/kyc_registration_tax_step.dart';

import '../../../helper/helper.dart';

const _switzerland = Country(id: 41, symbol: 'CH', name: 'Switzerland', kycAllowed: true);
const _germany = Country(id: 49, symbol: 'DE', name: 'Germany', kycAllowed: true);

void main() {
  setUpAll(() {
    final countryService = MockDfxCountryService();
    when(() => countryService.getAllCountries())
        .thenAnswer((_) async => <Country>[_switzerland, _germany]);
    GetIt.instance.registerSingleton<DfxCountryService>(countryService);
  });

  tearDownAll(() async => GetIt.instance.reset());

  Widget buildSubject(Country? taxCountry) => wrapForGolden(
        Scaffold(
          body: KycRegistrationTaxStep(
            taxCountryCtrl: ValueNotifier<Country?>(taxCountry),
            tinCtrl: TextEditingController(),
            onSubmit: () async {},
          ),
        ),
      );

  group('$KycRegistrationTaxStep', () {
    // Two meaningful states: no TIN (nothing picked, or a Swiss tax residence)
    // vs. the TIN revealed for a non-Swiss tax residence. Swiss and empty render
    // identically here (the picker has no initial value, so both just show the
    // hint), so the no-TIN state is captured once.
    goldenTest(
      'no TIN field without a non-Swiss tax residence',
      fileName: 'kyc_registration_tax_step_default',
      constraints: phoneConstraints,
      builder: () => buildSubject(null),
    );

    goldenTest(
      'non-Swiss tax residence reveals the TIN field',
      fileName: 'kyc_registration_tax_step_non_swiss',
      constraints: phoneConstraints,
      builder: () => buildSubject(_germany),
    );
  });
}
