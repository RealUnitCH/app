import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/utils/fiat_amount.dart';

void main() {
  group('chargedFiatAmount', () {
    // The quote is always requested with this rounded integer, so the SEPA
    // transfer / QR the API builds encodes it.
    test('rounds a dot decimal to the charged integer (300.75 → 301)', () {
      expect(chargedFiatAmount('300.75'), 301);
    });

    test('normalises a comma decimal (300,75 → 301)', () {
      expect(chargedFiatAmount('300,75'), 301);
    });

    test('leaves a whole amount unchanged (300 → 300)', () {
      expect(chargedFiatAmount('300'), 300);
    });

    test('treats an empty string as zero', () {
      expect(chargedFiatAmount(''), 0);
    });

    test('rounds half away from zero and down below the half (0.5 → 1, 1.49 → 1)', () {
      expect(chargedFiatAmount('0.5'), 1);
      expect(chargedFiatAmount('1.49'), 1);
    });

    test('throws on structurally invalid input instead of guessing', () {
      expect(() => chargedFiatAmount('1.300,75'), throwsFormatException);
      expect(() => chargedFiatAmount('3,5,7'), throwsFormatException);
    });
  });

  group('tryParseFiatAmount', () {
    test('accepts a comma decimal', () {
      expect(tryParseFiatAmount('300,75'), 300.75);
    });

    test('returns null on multi-separator input', () {
      expect(tryParseFiatAmount('1.300,75'), isNull);
    });
  });
}
