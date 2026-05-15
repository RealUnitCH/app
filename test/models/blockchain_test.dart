import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/models/blockchain.dart';

void main() {
  group('$Blockchain', () {
    test('values is exactly {ethereum, sepolia}', () {
      // Catches a third blockchain being added without updating every
      // chainId switch + Blockchain.getFromChainId caller.
      expect(Blockchain.values, hasLength(2));
      expect(Blockchain.values, contains(Blockchain.ethereum));
      expect(Blockchain.values, contains(Blockchain.sepolia));
    });

    test('Ethereum carries chainId 1, name "Ethereum", nativeSymbol "ETH"', () {
      expect(Blockchain.ethereum.chainId, 1);
      expect(Blockchain.ethereum.name, 'Ethereum');
      expect(Blockchain.ethereum.nativeSymbol, 'ETH');
    });

    test('Sepolia carries chainId 11155111, name "Sepolia", nativeSymbol "ETH"', () {
      expect(Blockchain.sepolia.chainId, 11155111);
      expect(Blockchain.sepolia.name, 'Sepolia');
      expect(Blockchain.sepolia.nativeSymbol, 'ETH');
    });

    group('getFromChainId', () {
      test('resolves mainnet by chainId 1', () {
        expect(Blockchain.getFromChainId(1), Blockchain.ethereum);
      });

      test('resolves Sepolia by chainId 11155111', () {
        expect(Blockchain.getFromChainId(11155111), Blockchain.sepolia);
      });

      test('throws StateError on an unknown chainId', () {
        expect(() => Blockchain.getFromChainId(42), throwsA(isA<StateError>()));
      });
    });

    group('nativeAsset', () {
      test('Ethereum native asset is ETH at 0x0 with 18 decimals', () {
        final asset = Blockchain.ethereum.nativeAsset;

        expect(asset.chainId, 1);
        expect(asset.address, '0x0');
        expect(asset.symbol, 'ETH');
        expect(asset.decimals, 18);
        expect(asset.name, 'Ethereum');
      });

      test('Sepolia native asset is ETH at 0x0 with 18 decimals', () {
        final asset = Blockchain.sepolia.nativeAsset;

        expect(asset.chainId, 11155111);
        expect(asset.symbol, 'ETH');
        expect(asset.decimals, 18);
      });
    });
  });
}
