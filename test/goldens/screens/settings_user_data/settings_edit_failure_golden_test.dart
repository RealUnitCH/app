import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/others/settings_edit_failure_page.dart';

import '../../../helper/helper.dart';

void main() {

  group('$SettingsEditFailurePage', () {
    goldenTest(
      'default failure state',
      fileName: 'settings_edit_failure_page_default',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        SettingsEditFailurePage(
          'Something went wrong',
          title: 'Change address',
          onRefresh: () {},
        ),
      ),
    );
  });
}
