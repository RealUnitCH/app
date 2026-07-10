import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/widgets/form/phone_number_field.dart';

import '../../helper/pump_app.dart';

class _PhoneFieldHarness {
  _PhoneFieldHarness({
    required this.formKey,
    required this.controller,
  });

  final GlobalKey<FormState> formKey;
  final ValueNotifier<String?> controller;
}

Future<_PhoneFieldHarness> _pumpPhoneField(
  WidgetTester tester, {
  String? initialPhoneNumber,
}) async {
  final formKey = GlobalKey<FormState>();
  final controller = ValueNotifier<String?>(initialPhoneNumber);
  addTearDown(controller.dispose);

  await tester.pumpApp(
    Scaffold(
      body: Form(
        key: formKey,
        child: PhoneNumberField(controller: controller),
      ),
    ),
  );

  return _PhoneFieldHarness(formKey: formKey, controller: controller);
}

Future<bool> _enterAndValidate(
  WidgetTester tester,
  _PhoneFieldHarness harness,
  String nationalNumber,
) async {
  await tester.enterText(find.byType(TextFormField), nationalNumber);

  final isValid = harness.formKey.currentState!.validate();
  await tester.pump();
  return isValid;
}

String _phoneError(WidgetTester tester, String Function(S localizations) message) {
  final context = tester.element(find.byType(PhoneNumberField));
  return message(S.of(context));
}

void main() {
  group('$PhoneNumberField', () {
    testWidgets('keeps the existing required error for empty input', (tester) async {
      final harness = await _pumpPhoneField(tester);

      final isValid = harness.formKey.currentState!.validate();
      await tester.pump();

      expect(isValid, isFalse);
      expect(
        find.text(_phoneError(tester, (s) => s.registerPhoneNumberInvalid)),
        findsOneWidget,
      );
      expect(harness.controller.value, isNull);
    });

    testWidgets('keeps the existing digits-only error for non-digit input', (tester) async {
      final harness = await _pumpPhoneField(tester);

      final isValid = await _enterAndValidate(tester, harness, '79abc4567');

      expect(isValid, isFalse);
      expect(
        find.text(_phoneError(tester, (s) => s.registerPhoneNumberOnlyDigits)),
        findsOneWidget,
      );
    });

    group('prefix +41 plausibility (exactly 9 national digits)', () {
      testWidgets('rejects an 8-digit national number as too short', (tester) async {
        final harness = await _pumpPhoneField(tester);

        final isValid = await _enterAndValidate(tester, harness, '12345678');

        expect(harness.controller.value, '+4112345678');
        expect(isValid, isFalse);
        expect(
          find.text(_phoneError(tester, (s) => s.registerPhoneNumberInvalidLength)),
          findsOneWidget,
        );
      });

      testWidgets('accepts a 9-digit national number', (tester) async {
        final harness = await _pumpPhoneField(tester);

        final isValid = await _enterAndValidate(tester, harness, '791234567');

        expect(harness.controller.value, '+41791234567');
        expect(isValid, isTrue);
        expect(
          find.text(_phoneError(tester, (s) => s.registerPhoneNumberInvalidLength)),
          findsNothing,
        );
      });

      testWidgets('rejects a 10-digit national number as too long', (tester) async {
        final harness = await _pumpPhoneField(tester);

        final isValid = await _enterAndValidate(tester, harness, '1234567890');

        expect(harness.controller.value, '+411234567890');
        expect(isValid, isFalse);
        expect(
          find.text(_phoneError(tester, (s) => s.registerPhoneNumberInvalidLength)),
          findsOneWidget,
        );
      });
    });

    group('prefix +49 plausibility (10 to 11 national digits)', () {
      testWidgets('rejects a 9-digit national number below the lower bound', (tester) async {
        final harness = await _pumpPhoneField(tester, initialPhoneNumber: '+49');

        final isValid = await _enterAndValidate(tester, harness, '123456789');

        expect(harness.controller.value, '+49123456789');
        expect(isValid, isFalse);
        expect(
          find.text(_phoneError(tester, (s) => s.registerPhoneNumberInvalidLength)),
          findsOneWidget,
        );
      });

      testWidgets('accepts a 10-digit national number at the lower bound', (tester) async {
        final harness = await _pumpPhoneField(tester, initialPhoneNumber: '+49');

        final isValid = await _enterAndValidate(tester, harness, '1234567890');

        expect(harness.controller.value, '+491234567890');
        expect(isValid, isTrue);
        expect(
          find.text(_phoneError(tester, (s) => s.registerPhoneNumberInvalidLength)),
          findsNothing,
        );
      });

      testWidgets('accepts an 11-digit national number at the upper bound', (tester) async {
        final harness = await _pumpPhoneField(tester, initialPhoneNumber: '+49');

        final isValid = await _enterAndValidate(tester, harness, '15123456789');

        expect(harness.controller.value, '+4915123456789');
        expect(isValid, isTrue);
        expect(
          find.text(_phoneError(tester, (s) => s.registerPhoneNumberInvalidLength)),
          findsNothing,
        );
      });

      testWidgets('rejects a 12-digit national number above the upper bound', (tester) async {
        final harness = await _pumpPhoneField(tester, initialPhoneNumber: '+49');

        final isValid = await _enterAndValidate(tester, harness, '123456789012');

        expect(harness.controller.value, '+49123456789012');
        expect(isValid, isFalse);
        expect(
          find.text(_phoneError(tester, (s) => s.registerPhoneNumberInvalidLength)),
          findsOneWidget,
        );
      });
    });

    testWidgets(
      'fails open for an unrecognised prefix and accepts a short national number',
      (tester) async {
        // An initial value whose prefix is neither +41 nor +49 leaves `prefix`
        // null in initState, so `_isPlausibleNationalNumber` reaches its
        // `default` branch and accepts any non-empty all-digit input.
        final harness = await _pumpPhoneField(tester, initialPhoneNumber: '+1555');

        final isValid = await _enterAndValidate(tester, harness, '12345');

        expect(isValid, isTrue);
        expect(
          find.text(_phoneError(tester, (s) => s.registerPhoneNumberInvalidLength)),
          findsNothing,
        );
      },
    );
    testWidgets('switching the country prefix recomposes the stored number', (tester) async {
      final harness = await _pumpPhoneField(tester, initialPhoneNumber: '+41791234567');

      // Drive the prefix dropdown's onChanged directly (deterministic, no
      // overlay menu): the national part is preserved and re-prefixed.
      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );
      dropdown.onChanged!('+49');
      await tester.pumpAndSettle();

      expect(harness.controller.value, '+49791234567');
    });
  });
}
