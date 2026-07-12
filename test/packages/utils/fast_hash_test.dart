import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/utils/fast_hash.dart';

void main() {
  group('fastHash', () {
    test('empty string returns the FNV-1a 64-bit offset basis', () {
      expect(fastHash(''), 0xcbf29ce484222325);
    });

    test('is deterministic for the same input', () {
      const input = 'realunit-asset-id';

      expect(fastHash(input), fastHash(input));
    });

    test('differs for distinct inputs', () {
      expect(fastHash('a'), isNot(fastHash('b')));
      expect(fastHash('aa'), isNot(fastHash('ab')));
    });

    test('handles unicode strings without throwing', () {
      // Two-byte code units exercise both halves of the FNV mixing loop.
      expect(() => fastHash('zürich'), returnsNormally);
      expect(fastHash('zürich'), isNot(fastHash('zurich')));
    });

    test('is sensitive to ordering (not a commutative hash)', () {
      expect(fastHash('ab'), isNot(fastHash('ba')));
    });
  });
}
