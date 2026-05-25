import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/legal/subpages/legal_document_page.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';

import '../../../helper/helper.dart';

void main() {
  late MockSettingsBloc settingsBloc;

  setUp(() {
    settingsBloc = MockSettingsBloc();
    when(() => settingsBloc.state).thenReturn(const SettingsState());
  });

  Widget buildSubject({String? initialMarkdownContent}) => BlocProvider<SettingsBloc>.value(
    value: settingsBloc,
    child: LegalDocumentPage(
      params: const LegalDocumentParams(
        title: 'Terms',
        assetBaseName: 'terms',
      ),
      initialMarkdownContent: initialMarkdownContent,
    ),
  );

  group('$LegalDocumentPage', () {
    goldenTest(
      'initial state before markdown loads',
      fileName: 'legal_document_page_default',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(buildSubject()),
    );

    // The page reads its markdown from rootBundle in production; for the
    // loaded golden we pass a representative head of assets/legal/terms_of_use_de.md
    // via the @visibleForTesting `initialMarkdownContent` parameter so the
    // page renders the Markdown body synchronously.
    goldenTest(
      'terms document loaded',
      fileName: 'legal_document_page_terms_loaded',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(
        buildSubject(
          initialMarkdownContent: _termsMarkdownStub,
        ),
      ),
    );
  });
}

/// Representative head of `assets/legal/terms_of_use_de.md` — kept inline so
/// the golden does not depend on the live asset file changing.
const _termsMarkdownStub = '''# Nutzungsbedingungen der RealUnit Wallet App

*Stand: Februar 2026*


## 1. Geltungsbereich

Diese Nutzungsbedingungen regeln die Verwendung der RealUnit Wallet App (nachfolgend «App»), herausgegeben von der RealUnit Schweiz AG, Schochenmühlestrasse 6, 6340 Baar, Schweiz (nachfolgend «RealUnit» oder «wir»).

Mit der Nutzung der App erklären Sie sich mit diesen Nutzungsbedingungen einverstanden. Für den Kauf und Verkauf von RealUnit Aktien-Token gelten zusätzlich die Allgemeinen Geschäftsbedingungen (AGB).


## 2. Beschreibung der App

Die App ist eine Self-Custody-Wallet für die Verwaltung von RealUnit Aktien-Token (REALU) und weiteren ERC-20-Token auf der Ethereum-Blockchain. Sie ermöglicht insbesondere:

- Erstellen und Wiederherstellen von Wallets mittels Wiederherstellungs-Wörtern (Seed Phrase)
- Empfangen und Senden von Token
- Anzeige von Guthaben und Transaktionshistorie
- Erstellung von Steuerberichten
- Anbindung von Hardware-Wallets (BitBox02)


## 3. Eigenverantwortung und Verwahrung

Die App ist eine Self-Custody-Lösung. Das bedeutet:
''';
