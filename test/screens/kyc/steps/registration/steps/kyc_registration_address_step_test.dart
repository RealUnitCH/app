import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/steps/kyc_registration_address_step.dart';

import '../../../../../helper/pump_app.dart';

class _MockDfxCountryService extends Mock implements DfxCountryService {}

const _ch = Country(id: 1, symbol: 'CH', name: 'Switzerland', kycAllowed: true);
const _de = Country(id: 2, symbol: 'DE', name: 'Germany', kycAllowed: true);

void main() {
  setUpAll(() {
    final countryService = _MockDfxCountryService();
    when(() => countryService.getAllCountries())
        .thenAnswer((_) async => const <Country>[]);
    GetIt.instance.registerSingleton<DfxCountryService>(countryService);
  });

  tearDownAll(() async => GetIt.instance.reset());

  // The step's TextFields require a Material ancestor; mirror the golden
  // harness by wrapping in a Scaffold.
  Widget buildStep(
    ValueNotifier<Country?> countryCtrl,
    ValueNotifier<bool> taxCtrl,
  ) => Scaffold(
    body: KycRegistrationAddressStep(
      addressStreetCtrl: TextEditingController(),
      addressNumberCtrl: TextEditingController(),
      postalCodeCtrl: TextEditingController(),
      cityCtrl: TextEditingController(),
      countryCtrl: countryCtrl,
      swissTaxResidenceCtrl: taxCtrl,
      onSubmit: () async {},
    ),
  );

  // BL-002 (#610 F4): the Swiss-tax-residence flag auto-ticks for a CH country
  // and clears for non-CH — until the user manually toggles it, after which the
  // country listener must stop overriding. This is the value the user signs.
  group('$KycRegistrationAddressStep swissTaxResidence (BL-002)', () {
    testWidgets('auto-ticks for CH and clears for non-CH', (tester) async {
      final country = ValueNotifier<Country?>(null);
      final tax = ValueNotifier<bool>(false);
      await tester.pumpApp(buildStep(country, tax));

      country.value = _ch;
      await tester.pump();
      expect(tax.value, isTrue, reason: 'CH must auto-tick swissTaxResidence');

      country.value = _de;
      await tester.pump();
      expect(tax.value, isFalse, reason: 'non-CH must clear it');
    });

    testWidgets('stops auto-overriding once the user toggles the checkbox', (tester) async {
      final country = ValueNotifier<Country?>(_de);
      final tax = ValueNotifier<bool>(false);
      await tester.pumpApp(buildStep(country, tax));

      // User manually ticks it → marks the field user-controlled. The form is
      // taller than the test viewport, so scroll the checkbox into view first.
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      expect(tax.value, isTrue);

      // A later CH selection must NOT auto-flip the user's choice...
      country.value = _ch;
      await tester.pump();
      expect(tax.value, isTrue, reason: 'manual toggle disables auto-override');

      // ...and neither must switching back to non-CH.
      country.value = _de;
      await tester.pump();
      expect(tax.value, isTrue);
    });
  });
}
