import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/steps/kyc_registration_tax_step.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

import '../../../../../helper/country_fixture.dart';
import '../../../../../helper/pump_app.dart';

// Ids match the committed country fixture (Country equality is id-keyed), so an
// initialCountry resolves against the list the real DfxCountryService loads.
const _switzerland = Country(id: 41, symbol: 'CH', name: 'Switzerland', kycAllowed: true);
const _germany = Country(id: 55, symbol: 'DE', name: 'Germany', kycAllowed: true);

void main() {
  setUp(() {
    GetIt.instance.registerSingleton<DfxCountryService>(fixtureCountryService());
  });

  tearDown(() async => GetIt.instance.reset());

  Future<_Harness> pump(WidgetTester tester, {Country? initialCountry}) async {
    final harness = _Harness();

    await tester.pumpApp(
      Scaffold(
        body: KycRegistrationTaxStep(
          taxCountryCtrl: harness.taxCountryCtrl,
          tinCtrl: harness.tinCtrl,
          initialCountry: initialCountry,
          onSubmit: () async => harness.submitCount++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return harness;
  }

  Finder scrollable() => find.byType(Scrollable).first;

  Future<void> selectTaxCountry(WidgetTester tester, String name) async {
    final dropdown = find.byType(DropdownButtonFormField<Country>);
    await tester.scrollUntilVisible(dropdown, 100, scrollable: scrollable());
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  Future<void> tapComplete(WidgetTester tester) async {
    final button = find.byType(AppFilledButton);
    await tester.scrollUntilVisible(button, 100, scrollable: scrollable());
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  group('$KycRegistrationTaxStep', () {
    testWidgets(
      'keeps the TIN field hidden for a Swiss tax residence',
      (tester) async {
        await pump(tester);
        await selectTaxCountry(tester, 'Switzerland');

        final context = tester.element(find.byType(KycRegistrationTaxStep));
        expect(find.text(S.of(context).taxIdentificationNumber), findsNothing);
      },
    );

    testWidgets(
      'reveals a required TIN field for a non-Swiss tax residence',
      (tester) async {
        final harness = await pump(tester);
        await selectTaxCountry(tester, 'Germany');

        final context = tester.element(find.byType(KycRegistrationTaxStep));
        expect(find.text(S.of(context).taxIdentificationNumber), findsOneWidget);

        // Submitting with an empty TIN must surface the required error and must
        // not fire onSubmit — the derived non-Swiss residence needs a TIN.
        await tapComplete(tester);

        expect(find.text(S.of(context).tinRequired), findsOneWidget);
        expect(harness.submitCount, 0);
      },
    );

    testWidgets(
      'rejects a whitespace-only TIN',
      (tester) async {
        final harness = await pump(tester);
        await selectTaxCountry(tester, 'Germany');

        final context = tester.element(find.byType(KycRegistrationTaxStep));
        final tinField = find.widgetWithText(TextFormField, S.of(context).tinHint);
        await tester.scrollUntilVisible(tinField, 100, scrollable: scrollable());
        await tester.enterText(tinField, '   ');
        await tester.pump();

        await tapComplete(tester);

        expect(find.text(S.of(context).tinRequired), findsOneWidget);
        expect(harness.submitCount, 0);
      },
    );

    testWidgets(
      'submits once a non-Swiss country and a TIN are provided',
      (tester) async {
        final harness = await pump(tester);
        await selectTaxCountry(tester, 'Germany');

        final context = tester.element(find.byType(KycRegistrationTaxStep));
        final tinField = find.widgetWithText(TextFormField, S.of(context).tinHint);
        await tester.scrollUntilVisible(tinField, 100, scrollable: scrollable());
        await tester.enterText(tinField, '12 345 678 901');
        await tester.pump();

        await tapComplete(tester);

        expect(harness.tinCtrl.text, '12 345 678 901');
        expect(harness.submitCount, 1);
      },
    );

    testWidgets(
      'submits a Swiss tax residence without requiring a TIN',
      (tester) async {
        final harness = await pump(tester);
        await selectTaxCountry(tester, 'Switzerland');

        await tapComplete(tester);

        expect(harness.submitCount, 1);
      },
    );

    testWidgets(
      'does not submit while no tax-residence country is picked',
      (tester) async {
        final harness = await pump(tester);

        // The mandatory country picker keeps the form invalid until a choice
        // is made, so onSubmit must never fire.
        await tapComplete(tester);

        expect(harness.submitCount, 0);
      },
    );

    testWidgets(
      'dismisses the keyboard when tapping outside the fields',
      (tester) async {
        await pump(tester);
        // Reveal the TIN field so there is a focusable input to clear.
        await selectTaxCountry(tester, 'Germany');

        final tinField = find
            .descendant(
              of: find.byType(KycRegistrationTaxStep),
              matching: find.byType(EditableText),
            )
            .first;
        final tinFocus = tester.widget<EditableText>(tinField).focusNode;
        await tester.tap(tinField);
        await tester.pump();
        expect(tinFocus.hasFocus, isTrue);

        // The opaque GestureDetector wrapping the form clears focus on tap.
        final dismissArea = find.ancestor(
          of: find.descendant(
            of: find.byType(KycRegistrationTaxStep),
            matching: find.byType(Form),
          ),
          matching: find.byWidgetPredicate(
            (w) => w is GestureDetector && w.behavior == HitTestBehavior.opaque && w.onTap != null,
          ),
        );
        expect(dismissArea, findsOneWidget);
        tester.widget<GestureDetector>(dismissArea).onTap!();
        await tester.pump();

        expect(tinFocus.hasFocus, isFalse);
      },
    );
  });

  group('$KycRegistrationTaxStep prefill', () {
    testWidgets(
      'pre-selects a non-Swiss initial country, propagating it and revealing the TIN',
      (tester) async {
        final harness = await pump(tester, initialCountry: _germany);

        // The residence country handed in as initialCountry propagates into the
        // controller (so the derived swissTaxResidence is set) and reveals the
        // required TIN — without any manual pick.
        expect(harness.taxCountryCtrl.value, _germany);
        final context = tester.element(find.byType(KycRegistrationTaxStep));
        expect(find.text(S.of(context).taxIdentificationNumber), findsOneWidget);
      },
    );

    testWidgets(
      'pre-selects a Swiss initial country without a TIN',
      (tester) async {
        final harness = await pump(tester, initialCountry: _switzerland);

        expect(harness.taxCountryCtrl.value, _switzerland);
        final context = tester.element(find.byType(KycRegistrationTaxStep));
        expect(find.text(S.of(context).taxIdentificationNumber), findsNothing);
      },
    );

    testWidgets(
      'submits the pre-selected Swiss residence without a manual pick',
      (tester) async {
        final harness = await pump(tester, initialCountry: _switzerland);

        // The prefill alone satisfies the mandatory country field.
        await tapComplete(tester);

        expect(harness.submitCount, 1);
      },
    );
  });
}

class _Harness {
  final taxCountryCtrl = ValueNotifier<Country?>(null);
  final tinCtrl = TextEditingController();
  int submitCount = 0;
}
