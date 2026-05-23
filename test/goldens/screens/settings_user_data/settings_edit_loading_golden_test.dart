import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/others/settings_edit_loading_page.dart';

import '../../../helper/helper.dart';

void main() {

  group('$SettingsEditLoadingPage', () {
    goldenTest(
      'default loading state',
      fileName: 'settings_edit_loading_page_default',
      // CircularProgressIndicator never settles; pump once to capture the
      // initial frame instead of letting pumpAndSettle hang.
      pumpBeforeTest: pumpOnce,
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        const SettingsEditLoadingPage(title: 'Change address'),
      ),
    );
  });
}
