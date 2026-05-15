import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';

void main() {
  group('default RealUnit assets', () {
    test('mainnet asset matches the production contract', () {
      // These constants are referenced by ApiConfig and the entire fiat
      // on/off-ramp pipeline. Pin them so an accidental edit (wrong
      // contract address / decimals) is caught instantly.
      expect(realUnitAsset.chainId, 1);
      expect(realUnitAsset.address, '0x553C7f9C780316FC1D34b8e14ac2465Ab22a090B');
      expect(realUnitAsset.symbol, 'REALU');
      expect(realUnitAsset.decimals, 0);
    });

    test('Sepolia testnet asset matches the dev contract', () {
      expect(realUnitTestAsset.chainId, 11155111);
      expect(realUnitTestAsset.address, '0x0add9824820508dd7992cbebb9f13fbe8e45a30f');
      expect(realUnitTestAsset.symbol, 'REALU');
      expect(realUnitTestAsset.decimals, 0);
    });

    test('mainnet and Sepolia assets are distinct objects', () {
      expect(realUnitAsset.address, isNot(realUnitTestAsset.address));
      expect(realUnitAsset.chainId, isNot(realUnitTestAsset.chainId));
    });

    test('asset-id constants are stable', () {
      expect(ethereumEthAssetId, 111);
      expect(sepoliaEthAssetId, 392);
      expect(ethereumZchfAssetId, 251);
      expect(sepoliaZchfAssetId, 418);
    });
  });
}
