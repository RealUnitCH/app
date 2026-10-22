import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/sell/widgets/sell_confirm_sheet.dart';

void main() {
  const fallback = 'That did not work. Please try again.';

  test('a caveat rejection reuses the existing localized sentence', () {
    expect(
      visibleSellConfirmError(
        error: 'Exception: EIP-7702 caveats: the caveat list is empty',
        caveatFallback: fallback,
      ),
      fallback,
    );
  });

  test('other confirm errors keep their existing text', () {
    expect(
      visibleSellConfirmError(
        error: 'Exception: signing cancelled',
        caveatFallback: fallback,
      ),
      'Exception: signing cancelled',
    );
  });
}
