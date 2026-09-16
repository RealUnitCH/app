import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/packages/utils/fast_hash.dart';

Balance _balance({
  int chainId = 1,
  String contract = '0xa',
  String wallet = '0xw',
  BigInt? amount,
}) =>
    Balance(
      chainId: chainId,
      contractAddress: contract,
      walletAddress: wallet,
      balance: amount ?? BigInt.zero,
      asset: realUnitAsset,
    );

void main() {
  group('$Balance', () {
    test('id is fastHash(walletAddress:chainId:contractAddress)', () {
      final b = _balance();

      expect(b.id, fastHash('0xw:1:0xa'));
    });

    test('balance amount is mutable (BigInt is a non-final field)', () {
      final b = _balance(amount: BigInt.from(10));

      b.balance = BigInt.from(20);

      expect(b.balance, BigInt.from(20));
    });

    test(
      'two Balances with the same (chain, contract, wallet) AND same amount are ==',
      () {
        final a = _balance(amount: BigInt.from(77994));
        final b = _balance(amount: BigInt.from(77994));

        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      },
    );

    test(
      'two Balances with the same slot tuple but different amounts are not ==',
      () {
        final a = _balance(amount: BigInt.from(77994));
        final b = _balance(amount: BigInt.from(85194));

        expect(a, isNot(equals(b)));
      },
    );

    test('id does not depend on amount', () {
      final a = _balance(amount: BigInt.from(77994));
      final b = _balance(amount: BigInt.from(85194));

      expect(a.id, b.id);
      expect(a.id, fastHash('0xw:1:0xa'));
    });

    test('a different chainId produces a different == identity', () {
      final a = _balance();
      final b = _balance(chainId: 2);

      expect(a, isNot(equals(b)));
    });

    test('a different walletAddress produces a different == identity', () {
      final a = _balance(wallet: '0xw1');
      final b = _balance(wallet: '0xw2');

      expect(a, isNot(equals(b)));
    });
  });
}
