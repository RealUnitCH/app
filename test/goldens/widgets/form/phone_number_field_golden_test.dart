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
  });
}
