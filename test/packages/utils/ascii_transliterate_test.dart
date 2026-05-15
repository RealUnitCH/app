import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/utils/ascii_transliterate.dart';

void main() {
  group('toBitboxSafeAscii', () {
    test('passes plain ASCII through unchanged', () {
      expect(toBitboxSafeAscii('Joshua'), 'Joshua');
      expect(toBitboxSafeAscii('+41790000000'), '+41790000000');
      expect(toBitboxSafeAscii(''), '');
      expect(toBitboxSafeAscii('test@example.com'), 'test@example.com');
    });

    test('expands German umlauts and eszett', () {
      expect(toBitboxSafeAscii('Joshua Krüger'), 'Joshua Krueger');
      expect(toBitboxSafeAscii('Schöne Straße'), 'Schoene Strasse');
      expect(toBitboxSafeAscii('ÜBER'), 'UeBER');
      expect(toBitboxSafeAscii('STRAẞE'), 'STRASSE');
    });

    test('collapses Romance-language accents to base letters', () {
      expect(toBitboxSafeAscii('André'), 'Andre');
      expect(toBitboxSafeAscii('François'), 'Francois');
      expect(toBitboxSafeAscii('Cœur'), 'Coeur');
      expect(toBitboxSafeAscii('Núñez'), 'Nunez');
      expect(toBitboxSafeAscii('São Paulo'), 'Sao Paulo');
    });

    test('handles Polish, Czech, Romanian, Turkish', () {
      expect(toBitboxSafeAscii('Łukasz'), 'Lukasz');
      expect(toBitboxSafeAscii('Wałęsa'), 'Walesa');
      expect(toBitboxSafeAscii('Český'), 'Cesky');
      expect(toBitboxSafeAscii('Žižkov'), 'Zizkov');
      expect(toBitboxSafeAscii('București'), 'Bucuresti');
      expect(toBitboxSafeAscii('İstanbul'), 'Istanbul');
    });

    test('handles Nordic letters', () {
      expect(toBitboxSafeAscii('Ærø'), 'Aeroe');
      expect(toBitboxSafeAscii('Tromsø'), 'Tromsoe');
      expect(toBitboxSafeAscii('Århus'), 'Arhus');
      expect(toBitboxSafeAscii('Þór'), 'Thor');
    });

    test('replaces non-Latin scripts and emojis with ?', () {
      expect(toBitboxSafeAscii('Михаил'), '??????');
      expect(toBitboxSafeAscii('Hello 🦊 world'), 'Hello ? world');
    });

    test('result is always printable ASCII', () {
      const inputs = [
        'Krüger', 'Müller', 'Strauß',
        'André', 'François', 'Cœur',
        'Núñez', 'São', 'Wałęsa', 'Český',
        'Tromsø', 'Reykjavík',
        'Iași', 'İstanbul',
      ];
      for (final input in inputs) {
        final out = toBitboxSafeAscii(input);
        expect(out.runes.every((r) => r >= 0x20 && r < 0x7F), isTrue,
            reason: '`$input` produced `$out`');
      }
    });
  });

  group('toBitboxSafeAsciiOrNull', () {
    test('returns null for null input', () => expect(toBitboxSafeAsciiOrNull(null), isNull));
    test('transliterates non-null input',
        () => expect(toBitboxSafeAsciiOrNull('Krüger'), 'Krueger'));
  });
}
