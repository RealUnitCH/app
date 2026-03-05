import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/legal/widgets/legal_document_button.dart';
import 'package:realunit_wallet/screens/settings_legal_documents/settings_legal_documents_page.dart';

import '../../helper/pump_app.dart';

void main() {
  group('$SettingsLegalDocumentsPage', () {
    testWidgets('renders initially correctly', (tester) async {
      await tester.pumpApp(const SettingsLegalDocumentsPage());

      expect(find.byType(SingleChildScrollView), findsOne);
      expect(find.byType(LegalDocumentButton), findsNWidgets(6));
    });
  });
}
