import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/settings_contact/settings_contact_page.dart';

import '../../../helper/helper.dart';

void main() {
  group('$SettingsContactPage', () {
    goldenTest(
      'default state',
      fileName: 'settings_contact_page_default',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(const SettingsContactPage()),
    );
  });
}
