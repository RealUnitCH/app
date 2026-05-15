import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/models/portfolio_value_point.dart';
import 'package:realunit_wallet/models/price_point.dart';

void main() {
  group('$PricePoint', () {
    test('holds asset + price + time as-is (no normalisation)', () {
      const asset = Asset(
        chainId: 1,
        address: '0xa',
        name: 'RealUnit',
        symbol: 'REALU',
        decimals: 0,
      );
      final point = PricePoint(
        asset: asset,
        price: BigInt.from(1234567890),
        time: DateTime.utc(2026, 5, 15, 10),
      );

      expect(point.asset, asset);
      expect(point.price, BigInt.from(1234567890));
      expect(point.time, DateTime.utc(2026, 5, 15, 10));
    });
  });

  group('$PortfolioValuePoint', () {
    test('holds value + balance + time as-is', () {
      final point = PortfolioValuePoint(
        value: BigInt.from(99999),
        balance: BigInt.from(42),
        time: DateTime.utc(2026, 5, 15, 10),
      );

      expect(point.value, BigInt.from(99999));
      expect(point.balance, BigInt.from(42));
      expect(point.time, DateTime.utc(2026, 5, 15, 10));
    });

    test('value field documents rappen/cents granularity (BigInt, not double)', () {
      // The doc comment on PortfolioValuePoint.value says rappen/cents — pin
      // the type so a refactor to double does not silently lose precision on
      // very large portfolios.
      final point = PortfolioValuePoint(
        value: BigInt.parse('100000000000000000000'),
        balance: BigInt.from(1),
        time: DateTime.utc(2026, 5, 15),
      );

      expect(point.value, isA<BigInt>());
      expect(point.value, BigInt.parse('100000000000000000000'));
    });
  });
}
