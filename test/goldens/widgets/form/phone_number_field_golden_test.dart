import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/widgets/form/phone_number_field.dart';

import '../../../helper/helper.dart';

void main() {
  group('$PhoneNumberField', () {
    goldenTest(
      'default empty phone number field',
      fileName: 'phone_number_field_default',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: PhoneNumberField(
              controller: ValueNotifier<String?>(null),
            ),
          ),
        ),
      ),
    );

    goldenTest(
      'phone number field showing the plausibility error',
      fileName: 'phone_number_field_plausibility_error',
      constraints: phoneConstraints,
      // The initial value is a valid +41 prefix followed by an implausible
      // 6-digit national number. `AutovalidateMode.always` runs the field
      // validator on first frame so the invalid-length error is rendered in
      // the captured golden.
      builder: () => wrapForGolden(
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              autovalidateMode: AutovalidateMode.always,
              child: PhoneNumberField(
                controller: ValueNotifier<String?>('+41123456'),
              ),
            ),
          ),
        ),
      ),
    );
  });
}
