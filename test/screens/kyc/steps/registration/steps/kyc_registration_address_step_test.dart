import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/steps/kyc_registration_address_step.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

import '../../../../../helper/pump_app.dart';

class _MockDfxCountryService extends Mock implements DfxCountryService {}

const _germany = Country(id: 49, symbol: 'DE', name: 'Germany', kycAllowed: true);
const _switzerland = Country(id: 41, symbol: 'CH', name: 'Switzerland', kycAllowed: true);

void main() {
  late _MockDfxCountryService countryService;

  setUp(() {
    countryService = _MockDfxCountryService();
    when(() => countryService.getAllCountries())
        .thenAnswer((_) async => <Country>[_switzerland, _germany]);
    GetIt.instance.registerSingleton<DfxCountryService>(countryService);
  });

  tearDown(() async => GetIt.instance.reset());

  Future<_Harness> pump(
    WidgetTester tester, {
    bool initialSwissTaxResidence = true,
  }) async {
    final harness = _Harness(
      swissTaxResidenceCtrl: ValueNotifier<bool>(initialSwissTaxResidence),
      taxCountryCtrl: ValueNotifier<Country?>(null),
      tinCtrl: TextEditingController(),
    );

    await tester.pumpApp(
      Scaffold(
        body: KycRegistrationAddressStep(
          addressStreetCtrl: harness.addressStreetCtrl,
          addressNumberCtrl: harness.addressNumberCtrl,
          postalCodeCtrl: harness.postalCodeCtrl,
          cityCtrl: harness.cityCtrl,
          countryCtrl: harness.countryCtrl,
          swissTaxResidenceCtrl: harness.swissTaxResidenceCtrl,
          taxCountryCtrl: harness.taxCountryCtrl,
          tinCtrl: harness.tinCtrl,
          onSubmit: () async => harness.submitCount++,
        ),
      ),
    );
    return harness;
  }

  group('$KycRegistrationAddressStep tax residence section', () {
    testWidgets(
      'hides tax-residence country and TIN fields when Swiss residence is true',
      (tester) async {
        await pump(tester, initialSwissTaxResidence: true);

        final context = tester.element(find.byType(KycRegistrationAddressStep));
        expect(find.text(S.of(context).taxResidenceCountry), findsNothing);
        expect(find.text(S.of(context).taxIdentificationNumber), findsNothing);
      },
    );

    testWidgets(
      'reveals tax-residence country and TIN fields when toggle is switched off',
      (tester) async {
        await pump(tester, initialSwissTaxResidence: true);

        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(KycRegistrationAddressStep));
        expect(find.text(S.of(context).taxResidenceCountry), findsOneWidget);
        expect(find.text(S.of(context).taxIdentificationNumber), findsOneWidget);
      },
    );

    testWidgets(
      're-hides the tax-residence fields when the toggle is switched back on',
      (tester) async {
        // Start in the revealed (non-Swiss) state, then flip the switch back
        // to Swiss-only and assert the section collapses again — the reveal
        // must be fully reversible so a user who toggles by mistake is not
        // left with a required, now-irrelevant TIN field gating submit.
        await pump(tester, initialSwissTaxResidence: false);

        final context = tester.element(find.byType(KycRegistrationAddressStep));
        expect(find.text(S.of(context).taxResidenceCountry), findsOneWidget);

        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        expect(find.text(S.of(context).taxResidenceCountry), findsNothing);
        expect(find.text(S.of(context).taxIdentificationNumber), findsNothing);
      },
    );

    testWidgets(
      'TIN validator surfaces a required error when the field is empty on submit',
      (tester) async {
        final harness = await pump(tester, initialSwissTaxResidence: false);
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(KycRegistrationAddressStep));

        // Scroll the Complete button into view — the step is a
        // SingleChildScrollView and the button can sit below the viewport.
        await tester.scrollUntilVisible(
          find.byType(AppFilledButton),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.byType(AppFilledButton));
        await tester.pump();

        expect(find.text(S.of(context).tinRequired), findsOneWidget);
        // The submit closure must never fire when validation fails — that is
        // exactly the gap this UI fixes (previous behavior: backend would
        // surface a global 400 after a successful client-side submit).
        expect(harness.submitCount, 0);
      },
    );

    testWidgets(
      'TIN entry is recorded verbatim in the controller',
      (tester) async {
        final harness = await pump(tester, initialSwissTaxResidence: false);
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(KycRegistrationAddressStep));
        final tinFinder = find.widgetWithText(
          TextFormField,
          S.of(context).tinHint,
        );
        await tester.scrollUntilVisible(
          tinFinder,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.enterText(tinFinder, '12 345 678 901');
        await tester.pump();

        expect(harness.tinCtrl.text, '12 345 678 901');
      },
    );
  });
}

class _Harness {
  _Harness({
    required this.swissTaxResidenceCtrl,
    required this.taxCountryCtrl,
    required this.tinCtrl,
  });

  final addressStreetCtrl = TextEditingController();
  final addressNumberCtrl = TextEditingController();
  final postalCodeCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final countryCtrl = ValueNotifier<Country?>(null);
  final ValueNotifier<bool> swissTaxResidenceCtrl;
  final ValueNotifier<Country?> taxCountryCtrl;
  final TextEditingController tinCtrl;
  int submitCount = 0;
}
