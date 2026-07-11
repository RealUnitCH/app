import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/steps/kyc_registration_address_step.dart';

import '../../../helper/helper.dart';

void main() {
  setUpAll(() {
    GetIt.instance.registerSingleton<DfxCountryService>(fixtureCountryService());
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
            onSubmit: () async {},
          ),
        ),
      ),
    );
  });
}
