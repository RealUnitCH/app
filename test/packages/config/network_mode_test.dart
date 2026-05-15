import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';

void main() {
  group('$NetworkMode', () {
    test('mainnet → isMainnet=true, isTestnet=false, name="Mainnet"', () {
      const mode = NetworkMode.mainnet;

      expect(mode.isMainnet, isTrue);
      expect(mode.isTestnet, isFalse);
      expect(mode.name, 'Mainnet');
    });

    test('testnet → isTestnet=true, isMainnet=false, name="Testnet"', () {
      const mode = NetworkMode.testnet;

      expect(mode.isTestnet, isTrue);
      expect(mode.isMainnet, isFalse);
      expect(mode.name, 'Testnet');
    });

    test('values has exactly the two enum entries (no accidental addition)', () {
      // Catches the case where someone adds a third NetworkMode (e.g. local)
      // without also updating all the switch-on-mode call sites.
      expect(NetworkMode.values, hasLength(2));
      expect(NetworkMode.values, contains(NetworkMode.mainnet));
      expect(NetworkMode.values, contains(NetworkMode.testnet));
    });
  });
}
