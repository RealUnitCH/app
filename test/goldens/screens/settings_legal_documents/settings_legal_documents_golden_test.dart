import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/settings_legal_documents/settings_legal_documents_page.dart';

import '../../../helper/helper.dart';

void main() {

  group('$SettingsLegalDocumentsPage', () {
    goldenTest(
      'default state',
      fileName: 'settings_legal_documents_page_default',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(const SettingsLegalDocumentsPage()),
    );
  });
}
