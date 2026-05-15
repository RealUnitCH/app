import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/widgets/mnemonic_field.dart';

void main() {
  group('SeedStringExtension.seedWords', () {
    test('splits a normal mnemonic into 12 words', () {
      const m = 'test test test test test test test test test test test junk';

      expect(m.seedWords, hasLength(12));
      expect(m.seedWords.last, 'junk');
    });

    test('collapses runs of whitespace (tabs, multiple spaces)', () {
      const m = '  abandon   abandon\tabandon ';

      expect(m.seedWords, ['abandon', 'abandon', 'abandon']);
    });

    test('returns an empty list for an empty / whitespace-only string', () {
      expect(''.seedWords, isEmpty);
      expect('   '.seedWords, isEmpty);
      expect('\t\n  '.seedWords, isEmpty);
    });

    test('trims leading and trailing whitespace', () {
      const m = '   one two three   ';

      expect(m.seedWords, ['one', 'two', 'three']);
    });

    test('preserves the order of the words', () {
      const m = 'alpha bravo charlie';

      expect(m.seedWords, ['alpha', 'bravo', 'charlie']);
    });
  });
}
