import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_legal_document_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/legal_document/dto/dfx_legal_document_dto.dart';
import 'package:realunit_wallet/screens/legal/subpages/legal_document_page.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';

import '../../../helper/helper.dart';

class _MockLegalDocumentService extends Mock implements DfxLegalDocumentService {}

class _MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState> implements SettingsBloc {}

// Pin der V17-Behauptung: Wenn die API keinen passenden Eintrag liefert,
// zeigt die Seite den "PDF nicht verfügbar"-Retry-State und NIE die
// alten hardcoded 2026-03-PDF-URLs. Wir testen bewusst nur den
// load-bearing State; die anderen Pfade (URL vorhanden / leerer
// languageCode-Fallback) sind unit-getestet in
// legal_document_page_test.dart.
void main() {
  late _MockLegalDocumentService legalService;
  late _MockSettingsBloc settingsBloc;

  setUp(() {
    legalService = _MockLegalDocumentService();
    settingsBloc = _MockSettingsBloc();
    when(() => settingsBloc.state).thenReturn(const SettingsState());
    if (GetIt.instance.isRegistered<DfxLegalDocumentService>()) {
      GetIt.instance.unregister<DfxLegalDocumentService>();
    }
    GetIt.instance.registerSingleton<DfxLegalDocumentService>(legalService);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets(
    'leere apiUrls ⇒ "PDF nicht verfügbar"-State, KEIN hardcoded RealUnit-PDF-Button',
    (tester) async {
      when(
        () => legalService.getDocuments(type: any(named: 'type')),
      ).thenAnswer((_) async => const <DfxLegalDocumentDto>[]);

      await tester.pumpApp(
        BlocProvider<SettingsBloc>.value(
          value: settingsBloc,
          child: const LegalDocumentPage(
            params: LegalDocumentParams(
              title: 'Registration',
              assetBaseName: 'registration_agreement',
              legalDocumentType: LegalDocumentType.registrationAgreement,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PDF not available — tap to retry'), findsOneWidget);
      expect(find.text('Original PDF'), findsNothing);
      // Doppelt absichern: Auch keiner der alten signierten Fallback-URLs
      // darf an irgendeiner Stelle hochkommen.
      expect(find.textContaining('260303_RegV'), findsNothing);
    },
  );
}
