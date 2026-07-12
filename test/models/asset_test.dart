import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/packages/utils/fast_hash.dart';

void main() {
  group('$Asset', () {
    test('id is derived from chainId + address via fastHash', () {
      const asset = Asset(
        chainId: 1,
        address: '0xdeadbeef',
        name: 'X',
        symbol: 'X',
        decimals: 18,
      );

      expect(asset.id, fastHash('1:0xdeadbeef'));
    });

    test('Asset.getId matches the instance getter', () {
      const asset = Asset(
        chainId: 11155111,
        address: '0xabc',
        name: 'Y',
        symbol: 'Y',
        decimals: 18,
      );

      expect(Asset.getId(11155111, '0xabc'), asset.id);
    });

    test('different chainIds produce different ids for the same address', () {
      const a = Asset(chainId: 1, address: '0xa', name: 'A', symbol: 'A', decimals: 18);
      const b = Asset(chainId: 2, address: '0xa', name: 'A', symbol: 'A', decimals: 18);

      expect(a.id, isNot(b.id));
    });

    test('different addresses produce different ids on the same chain', () {
      const a = Asset(chainId: 1, address: '0xa', name: 'A', symbol: 'A', decimals: 18);
      const b = Asset(chainId: 1, address: '0xb', name: 'A', symbol: 'A', decimals: 18);

      expect(a.id, isNot(b.id));
    });

    test('id is deterministic across instances with the same chain+address', () {
      const a = Asset(chainId: 1, address: '0xa', name: 'A', symbol: 'A', decimals: 6);
      const b = Asset(chainId: 1, address: '0xa', name: 'Different', symbol: 'B', decimals: 18);

      // id only depends on chainId + address, not metadata.
      expect(a.id, b.id);
    });
  });
}
