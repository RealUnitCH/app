import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/styles/language.dart';

void main() {
  group('$Language', () {
    test('en and de carry their wire codes and flag asset paths', () {
      expect(Language.en.code, 'en');
      expect(Language.en.imagePath, 'assets/images/flags/gbr.png');
      expect(Language.de.code, 'de');
      expect(Language.de.imagePath, 'assets/images/flags/deu.png');
    });

    test('values has exactly the two entries', () {
      expect(Language.values, hasLength(2));
      expect(Language.values, contains(Language.en));
      expect(Language.values, contains(Language.de));
    });

    group('fromCode', () {
      test('resolves "en" and "de"', () {
        expect(Language.fromCode('en'), Language.en);
        expect(Language.fromCode('de'), Language.de);
      });

      test('is case-SENSITIVE on the input (matches the production lookup)', () {
        // Documents the current behaviour: codes are lowercase on the wire,
        // and the lookup does NOT lowercase the input. Different from
        // Currency.fromCode which normalises with toUpperCase.
        expect(() => Language.fromCode('EN'), throwsA(isA<StateError>()));
        expect(() => Language.fromCode('De'), throwsA(isA<StateError>()));
      });

      test('throws StateError on an unknown code', () {
        expect(() => Language.fromCode('fr'), throwsA(isA<StateError>()));
        expect(() => Language.fromCode(''), throwsA(isA<StateError>()));
      });
    });
  });
}
