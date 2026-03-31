import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/config/legal_documents_config.dart';
import 'package:realunit_wallet/screens/settings_legal_documents/settings_legal_documents_page.dart';
import 'package:realunit_wallet/widgets/outlined_tile.dart';

import '../../helper/pump_app.dart';

void main() {
  group('$SettingsLegalDocumentsPage', () {
    testWidgets('renders initially correctly', (tester) async {
      await tester.pumpApp(
        const SettingsLegalDocumentsPage(),
      );

      expect(find.byType(SingleChildScrollView), findsOne);
      // terms of use (1), legal documents, aktionariat & dfx (2)
      expect(
        find.byType(OutlinedTile),
        findsNWidgets(LegalDocumentsConfig.allDocuments.length + 1 + 2),
      );
    });
  });
}
