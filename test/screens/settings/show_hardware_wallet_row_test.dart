import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/settings/settings_page.dart';

void main() {
  group('showHardwareWalletRow', () {
    test('true only when the software balance is positive and no BitBox is paired', () {
      expect(
        showHardwareWalletRow(softwareBalancePositive: true, bitboxPaired: false),
        isTrue,
      );
      expect(
        showHardwareWalletRow(softwareBalancePositive: false, bitboxPaired: false),
        isFalse,
      );
      expect(
        showHardwareWalletRow(softwareBalancePositive: true, bitboxPaired: true),
        isFalse,
      );
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
