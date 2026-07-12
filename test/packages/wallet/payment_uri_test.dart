import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/wallet/payment_uri.dart';

void main() {
  group('$EthereumURI', () {
    const address = '0x0000000000000000000000000000000000000001';

    test('omits the amount query when the amount string is empty', () {
      final uri = EthereumURI(amount: '', address: address);

      expect(uri.toString(), 'ethereum:$address');
    });

    test('appends a non-empty amount as a query parameter', () {
      final uri = EthereumURI(amount: '1.5', address: address);

      expect(uri.toString(), 'ethereum:$address?amount=1.5');
    });

    test("normalises the decimal separator from ',' to '.'", () {
      // German locale formatters emit '1,5' — the URI must still parse as
      // a numeric amount on the receiving side, which expects '.'.
      final uri = EthereumURI(amount: '1,5', address: address);

      expect(uri.toString(), 'ethereum:$address?amount=1.5');
    });

    test('preserves dotted amounts unchanged', () {
      final uri = EthereumURI(amount: '0.000001', address: address);

      expect(uri.toString(), 'ethereum:$address?amount=0.000001');
    });

    // Amount is not URI-encoded, but both call sites hardcode amount='' so this
    // is unreachable today. Kept as defense-in-depth if the receive flow ever
    // accepts user-supplied amounts.
    test('amount with special characters is not URI-encoded (currently unreachable)', () {
      final uri = EthereumURI(amount: '1.5&evil=1', address: address);

      expect(uri.toString(), contains('&evil'));
    });
  });
}
