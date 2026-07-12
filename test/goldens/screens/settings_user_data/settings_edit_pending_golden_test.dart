import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/others/settings_edit_pending_page.dart';

import '../../../helper/helper.dart';

void main() {

  group('$SettingsEditPendingPage', () {
    goldenTest(
      'default pending state',
      fileName: 'settings_edit_pending_page_default',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        SettingsEditPendingPage(
          title: 'Change address',
          onRefresh: () {},
        ),
      ),
    );
  });
}
