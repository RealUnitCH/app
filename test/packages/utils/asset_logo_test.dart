import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/packages/utils/asset_logo.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';

const _ethMainnet = Asset(
  chainId: 1,
  address: '0x0',
  name: 'Ethereum',
  symbol: 'ETH',
  decimals: 18,
);

void main() {
  group('getAssetImagePath', () {
    test('mainnet ETH (chainId 1 + 0x0) → ETH.png', () {
      expect(getAssetImagePath(_ethMainnet), 'assets/images/coins/ETH.png');
    });

    test('mainnet RealUnit token → REALU.png', () {
      expect(getAssetImagePath(realUnitAsset), 'assets/images/coins/REALU.png');
    });

    test('Sepolia RealUnit token → REALU.png', () {
      expect(getAssetImagePath(realUnitTestAsset), 'assets/images/coins/REALU.png');
    });

    test('case-insensitive RealUnit address match (production code lowercases)', () {
      // Pass the mainnet address with mixed case — should still hit the REALU branch.
      const mixedCase = Asset(
        chainId: 1,
        address: '0x553C7f9C780316FC1D34b8e14ac2465Ab22a090B',
        name: 'RealUnit Token',
        symbol: 'REALU',
        decimals: 0,
      );

      expect(getAssetImagePath(mixedCase), 'assets/images/coins/REALU.png');
    });

    test('unknown chain/address falls back to REALU.png (default branch)', () {
      const unknown = Asset(
        chainId: 999,
        address: '0xdeadbeef',
        name: 'Mystery',
        symbol: 'XXX',
        decimals: 18,
      );

      // The default branch returns REALU.png — pinned because changing this
      // would silently render every unknown asset as ETH.
      expect(getAssetImagePath(unknown), 'assets/images/coins/REALU.png');
    });
  });

  group('getChainImagePath', () {
    test('Ethereum mainnet → ETH.png', () {
      expect(getChainImagePath(1), 'assets/images/coins/ETH.png');
    });

    test('Sepolia → ETH.png', () {
      expect(getChainImagePath(11155111), 'assets/images/coins/ETH.png');
    });
  });
}
