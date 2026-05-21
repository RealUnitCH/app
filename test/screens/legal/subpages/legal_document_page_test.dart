import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/legal/subpages/legal_document_page.dart';

void main() {
  group('$LegalDocumentPage.resolvePdfUrl', () {
    const apiUrls = {
      'de': 'https://api.test/de.pdf',
      'en': 'https://api.test/en.pdf',
    };
    const fallback = {
      'de': 'https://fallback.test/de.pdf',
      'en': 'https://fallback.test/en.pdf',
    };

    test('prefers API URL when API responded with the requested language', () {
      final url = resolveLegalDocumentPdfUrl(
        apiUrls: apiUrls,
        fallbackUrls: fallback,
        languageCode: 'de',
      );
      expect(url, 'https://api.test/de.pdf');
    });

    test('prefers API but degrades to first API URL when language missing', () {
      final url = resolveLegalDocumentPdfUrl(
        apiUrls: const {'en': 'https://api.test/en.pdf'},
        fallbackUrls: fallback,
        languageCode: 'de',
      );
      expect(url, 'https://api.test/en.pdf');
    });

    test('falls back to bundled map when API returned no entries', () {
      final url = resolveLegalDocumentPdfUrl(
        apiUrls: const {},
        fallbackUrls: fallback,
        languageCode: 'de',
      );
      expect(url, 'https://fallback.test/de.pdf');
    });

    test('falls back to bundled map when API load not yet finished', () {
      final url = resolveLegalDocumentPdfUrl(
        apiUrls: null,
        fallbackUrls: fallback,
        languageCode: 'en',
      );
      expect(url, 'https://fallback.test/en.pdf');
    });

    test('returns null when neither API nor fallback have URLs', () {
      final url = resolveLegalDocumentPdfUrl(
        apiUrls: const {},
        fallbackUrls: const {},
        languageCode: 'de',
      );
      expect(url, isNull);
    });

    test('returns null when fallback is null and API empty', () {
      final url = resolveLegalDocumentPdfUrl(
        apiUrls: const {},
        fallbackUrls: null,
        languageCode: 'de',
      );
      expect(url, isNull);
    });

    test('falls back to first fallback URL when language missing in fallback', () {
      final url = resolveLegalDocumentPdfUrl(
        apiUrls: null,
        fallbackUrls: const {'en': 'https://fallback.test/en.pdf'},
        languageCode: 'de',
      );
      expect(url, 'https://fallback.test/en.pdf');
    });
  });
}
