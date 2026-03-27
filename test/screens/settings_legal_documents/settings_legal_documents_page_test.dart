import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/config/legal_documents_config.dart';
import 'package:realunit_wallet/screens/legal/widgets/legal_document_button.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/settings_legal_documents/settings_legal_documents_page.dart';

import '../../helper/pump_app.dart';

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

void main() {
  late MockSettingsBloc settingsBloc;

  setUp(() {
    settingsBloc = MockSettingsBloc();
    when(() => settingsBloc.state).thenReturn(const SettingsState());
  });

  group('$SettingsLegalDocumentsPage', () {
    testWidgets('renders initially correctly', (tester) async {
      await tester.pumpApp(
        BlocProvider<SettingsBloc>.value(
          value: settingsBloc,
          child: const SettingsLegalDocumentsPage(),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOne);
      // Terms of Use: 1
      // allDocuments (RealUnit docs): 7
      // Navigation buttons (Aktionariat, DFX): 2
      // Total: 10
      expect(
        find.byType(LegalDocumentButton),
        findsNWidgets(LegalDocumentsConfig.allDocuments.length + 1 + 2),
      );
    });
  });
}
