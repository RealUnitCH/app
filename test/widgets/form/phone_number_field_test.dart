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
    testWidgets('shows the required error for empty input', (tester) async {
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

    testWidgets('shows the digits-only error for non-digit input', (tester) async {
      final harness = await _pumpPhoneField(tester);

      final isValid = await _enterAndValidate(tester, harness, '79abc4567');

      expect(isValid, isFalse);
      expect(
        find.text(_phoneError(tester, (s) => s.registerPhoneNumberOnlyDigits)),
        findsOneWidget,
      );
    });

    testWidgets('shows the too-short error for a number below the minimum length', (tester) async {
      final harness = await _pumpPhoneField(tester);

      // Fewer than 6 digits is the only client-side length rule; anything
      // longer is left to the DFX API, which owns phone-number validation.
      final isValid = await _enterAndValidate(tester, harness, '12345');

      expect(harness.controller.value, '+4112345');
      expect(isValid, isFalse);
      expect(
        find.text(_phoneError(tester, (s) => s.registerPhoneNumberTooShort)),
        findsOneWidget,
      );
    });

    testWidgets('accepts a number at the minimum length boundary', (tester) async {
      final harness = await _pumpPhoneField(tester);

      final isValid = await _enterAndValidate(tester, harness, '123456');

      expect(harness.controller.value, '+41123456');
      expect(isValid, isTrue);
    });

    testWidgets('accepts a representative national number', (tester) async {
      final harness = await _pumpPhoneField(tester);

      final isValid = await _enterAndValidate(tester, harness, '791234567');

      expect(harness.controller.value, '+41791234567');
      expect(isValid, isTrue);
    });

    testWidgets('prepends the selected prefix and applies the same length rule', (tester) async {
      final harness = await _pumpPhoneField(tester, initialPhoneNumber: '+49');

      final isValid = await _enterAndValidate(tester, harness, '15123456789');

      expect(harness.controller.value, '+4915123456789');
      expect(isValid, isTrue);
    });
  });
}
