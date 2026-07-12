import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/utils/swiss_payment_text.dart';

void main() {
  group('isSwissPaymentText', () {
    group('empty / null', () {
      test('null is valid (callers chain a non-empty check)', () {
        expect(isSwissPaymentText(null), isTrue);
      });

      test('empty string is valid', () {
        expect(isSwissPaymentText(''), isTrue);
      });
    });

    group('printable ASCII', () {
      test('plain Latin words pass', () {
        expect(isSwissPaymentText('Hello World'), isTrue);
      });

      test('digits pass', () {
        expect(isSwissPaymentText('12345 67890'), isTrue);
      });

      test('common punctuation passes', () {
        expect(isSwissPaymentText("It's @ #1 / 50%."), isTrue);
        expect(isSwissPaymentText('Strasse 1, 8001'), isTrue);
        expect(isSwissPaymentText('a-b_c.d'), isTrue);
      });

      test('all printable ASCII range pass', () {
        // 0x20 (space) through 0x7E (~) — the full printable ASCII band.
        final all = String.fromCharCodes(List.generate(0x7F - 0x20, (i) => 0x20 + i));
        expect(isSwissPaymentText(all), isTrue);
      });
    });

    group('Latin diacritics — uppercase', () {
      test('German umlauts and ß', () {
        expect(isSwissPaymentText('ÄÖÜß'), isTrue);
      });

      test('French accents', () {
        expect(isSwissPaymentText('ÀÂÇÈÉÊËÎÏÔÙÛÜŸ'), isFalse,
            reason: 'Ÿ is NOT in the Swiss payment set');
        expect(isSwissPaymentText('ÀÂÇÈÉÊËÎÏÔÙÛÜ'), isTrue);
      });

      test('Italian accents', () {
        expect(isSwissPaymentText('ÀÉÈÌÒÓÙ'), isTrue);
      });
    });

    group('Latin diacritics — lowercase', () {
      test('German lowercase umlauts', () {
        expect(isSwissPaymentText('äöü'), isTrue);
      });

      test('French + Italian lowercase accents', () {
        expect(isSwissPaymentText('àâçèéêëîïôùûü'), isTrue);
        expect(isSwissPaymentText('íóñý'), isTrue);
      });
    });

    group('real Swiss names + addresses', () {
      test('Rüttimann', () {
        expect(isSwissPaymentText('Rüttimann'), isTrue);
      });

      test('Münchwilen', () {
        expect(isSwissPaymentText('Münchwilen'), isTrue);
      });

      test('Genève', () {
        expect(isSwissPaymentText('Genève'), isTrue);
      });

      test('Saint-Légier', () {
        expect(isSwissPaymentText('Saint-Légier'), isTrue);
      });

      test('François', () {
        expect(isSwissPaymentText('François'), isTrue);
      });

      test("D'Hauterive", () {
        expect(isSwissPaymentText("D'Hauterive"), isTrue);
      });
    });

    group('non-Latin scripts → invalid', () {
      test('Chinese rejected', () {
        expect(isSwissPaymentText('王小明'), isFalse);
      });

      test('Cyrillic rejected', () {
        expect(isSwissPaymentText('Иван'), isFalse);
      });

      test('Japanese rejected', () {
        expect(isSwissPaymentText('日本語'), isFalse);
      });

      test('Arabic rejected', () {
        expect(isSwissPaymentText('محمد'), isFalse);
      });

      test('Hebrew rejected', () {
        expect(isSwissPaymentText('שלום'), isFalse);
      });

      test('emoji rejected', () {
        expect(isSwissPaymentText('Hello 👋'), isFalse);
      });
    });

    group('mixed valid + invalid', () {
      test('Latin name with single Cyrillic char fails', () {
        expect(isSwissPaymentText('Müllеr'), isFalse,
            reason: 'second-to-last is Cyrillic е (U+0435), not Latin e');
      });

      test('valid prefix + invalid suffix fails', () {
        expect(isSwissPaymentText('Hello 王'), isFalse);
      });
    });

    group('whitespace / control', () {
      test('newline allowed (multi-line memos)', () {
        expect(isSwissPaymentText('Line 1\nLine 2'), isTrue);
      });

      test('tab rejected', () {
        expect(isSwissPaymentText('a\tb'), isFalse);
      });

      test('carriage return rejected', () {
        expect(isSwissPaymentText('a\rb'), isFalse);
      });

      test('whitespace-only is valid (spaces are printable ASCII 0x20)', () {
        expect(isSwissPaymentText('   '), isTrue);
      });
    });

    group('uncommon Latin diacritics — not in Swiss payment set', () {
      test('Polish ąć rejected', () {
        expect(isSwissPaymentText('Łódź'), isFalse);
      });

      test('Portuguese ã rejected', () {
        expect(isSwissPaymentText('São Paulo'), isFalse);
      });

      test('Norwegian øå rejected', () {
        expect(isSwissPaymentText('Tromsø'), isFalse);
      });

      test('French ligature œ rejected (not in Swiss payment set)', () {
        expect(isSwissPaymentText('cœur'), isFalse);
      });
    });
  });
}
