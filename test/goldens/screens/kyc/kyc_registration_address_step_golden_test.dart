import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/steps/kyc_registration_address_step.dart';

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

  group('$KycRegistrationAddressStep', () {
    goldenTest(
      'empty address form',
      fileName: 'kyc_registration_address_step_default',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        Scaffold(
          body: KycRegistrationAddressStep(
            addressStreetCtrl: TextEditingController(),
            addressNumberCtrl: TextEditingController(),
            postalCodeCtrl: TextEditingController(),
            cityCtrl: TextEditingController(),
            countryCtrl: ValueNotifier<Country?>(null),
            swissTaxResidenceCtrl: ValueNotifier<bool>(true),
            taxCountryCtrl: ValueNotifier<Country?>(null),
            tinCtrl: TextEditingController(),
            onSubmit: () async {},
          ),
        ),
      ),
    );

    goldenTest(
      'non-Swiss tax residence reveals country + TIN fields',
      fileName: 'kyc_registration_address_step_non_swiss',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        Scaffold(
          body: KycRegistrationAddressStep(
            addressStreetCtrl: TextEditingController(),
            addressNumberCtrl: TextEditingController(),
            postalCodeCtrl: TextEditingController(),
            cityCtrl: TextEditingController(),
            countryCtrl: ValueNotifier<Country?>(null),
            swissTaxResidenceCtrl: ValueNotifier<bool>(false),
            taxCountryCtrl: ValueNotifier<Country?>(null),
            tinCtrl: TextEditingController(),
            onSubmit: () async {},
          ),
        ),
      ),
    );
  });
}
