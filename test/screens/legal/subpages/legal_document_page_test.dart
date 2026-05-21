import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/legal/subpages/legal_document_page.dart';

void main() {
  group('$LegalDocumentPage.resolvePdfUrl', () {
    const apiUrls = {
      'de': 'https://api.test/de.pdf',
      'en': 'https://api.test/en.pdf',
      'fr': 'https://api.test/fr.pdf',
    };

    test('exakter Sprach-Match gewinnt', () {
      expect(
        resolveLegalDocumentPdfUrl(apiUrls: apiUrls, languageCode: 'de'),
        'https://api.test/de.pdf',
      );
      expect(
        resolveLegalDocumentPdfUrl(apiUrls: apiUrls, languageCode: 'en'),
        'https://api.test/en.pdf',
      );
    });

    test('fehlt languageCode in apiUrls ⇒ deterministisch en > de > erste', () {
      // 'it' fehlt → en kommt zuerst nach languageCode
      expect(
        resolveLegalDocumentPdfUrl(apiUrls: apiUrls, languageCode: 'it'),
        'https://api.test/en.pdf',
      );
      // ohne en → de
      expect(
        resolveLegalDocumentPdfUrl(
          apiUrls: const {
            'de': 'https://api.test/de.pdf',
            'fr': 'https://api.test/fr.pdf',
          },
          languageCode: 'it',
        ),
        'https://api.test/de.pdf',
      );
      // ohne en und de → erster Insertion-Order-Eintrag (stabil für API-
      // Antworten, dokumentiert als letzte Eskalation, nicht produktiv
      // verwendet, weil API immer mindestens en oder de liefert).
      expect(
        resolveLegalDocumentPdfUrl(
          apiUrls: const {
            'fr': 'https://api.test/fr.pdf',
            'it': 'https://api.test/it.pdf',
          },
          languageCode: 'es',
        ),
        'https://api.test/fr.pdf',
      );
    });

    test('Reihenfolge en vor de ist stabil unabhängig von Insertion-Order', () {
      // de zuerst, en zweitens → Resolver nimmt en
      expect(
        resolveLegalDocumentPdfUrl(
          apiUrls: const {
            'de': 'https://api.test/de.pdf',
            'en': 'https://api.test/en.pdf',
          },
          languageCode: 'pt',
        ),
        'https://api.test/en.pdf',
      );
      // en zuerst, de zweitens → trotzdem en
      expect(
        resolveLegalDocumentPdfUrl(
          apiUrls: const {
            'en': 'https://api.test/en.pdf',
            'de': 'https://api.test/de.pdf',
          },
          languageCode: 'pt',
        ),
        'https://api.test/en.pdf',
      );
    });

    test('leere apiUrls ⇒ null (kein hardcoded Fallback, audit V17)', () {
      expect(
        resolveLegalDocumentPdfUrl(apiUrls: const {}, languageCode: 'de'),
        isNull,
      );
    });
  });
}
