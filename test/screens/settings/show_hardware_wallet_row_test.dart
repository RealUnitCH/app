import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/settings/settings_page.dart';

void main() {
  group('showHardwareWalletRow', () {
    test('true while no BitBox is paired, regardless of balance', () {
      expect(showHardwareWalletRow(bitboxPaired: false), isTrue);
      expect(showHardwareWalletRow(bitboxPaired: true), isFalse);
    });
  });

  group('showMoveBalanceRow', () {
    test('true only when both wallets exist', () {
      expect(showMoveBalanceRow(hasSoftware: true, hasBitbox: true), isTrue);
      expect(showMoveBalanceRow(hasSoftware: true, hasBitbox: false), isFalse);
      expect(showMoveBalanceRow(hasSoftware: false, hasBitbox: true), isFalse);
    });
  });
}
