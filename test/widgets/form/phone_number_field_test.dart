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

    testWidgets('rejects an implausible Swiss national number', (tester) async {
      final harness = await _pumpPhoneField(tester);

      final isValid = await _enterAndValidate(tester, harness, '123456');

      expect(harness.controller.value, '+41123456');
      expect(isValid, isFalse);
    });

    testWidgets('accepts a representative Swiss national number', (tester) async {
      final harness = await _pumpPhoneField(tester);

      final isValid = await _enterAndValidate(tester, harness, '791234567');

      expect(harness.controller.value, '+41791234567');
      expect(isValid, isTrue);
    });

    testWidgets('rejects an implausible German national number', (tester) async {
      final harness = await _pumpPhoneField(tester, initialPhoneNumber: '+49');

      final isValid = await _enterAndValidate(tester, harness, '123456');

      expect(harness.controller.value, '+49123456');
      expect(isValid, isFalse);
    });

    testWidgets('accepts a representative German national number', (tester) async {
      final harness = await _pumpPhoneField(tester, initialPhoneNumber: '+49');

      final isValid = await _enterAndValidate(tester, harness, '15123456789');

      expect(harness.controller.value, '+4915123456789');
      expect(isValid, isTrue);
    });
  });
}
