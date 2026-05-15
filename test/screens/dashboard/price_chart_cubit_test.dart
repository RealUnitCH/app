import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/models/price_point.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/price_chart/price_chart_cubit.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/price_chart/price_chart_state.dart';
import 'package:realunit_wallet/screens/dashboard/models/time_period.dart';

PricePoint _pp(DateTime time, int rappen) =>
    PricePoint(asset: realUnitAsset, price: BigInt.from(rappen), time: time);

void main() {
  group('$PriceChartCubit', () {
    test('empty price list yields the zero-window initial-shape state', () {
      final cubit = PriceChartCubit(const []);

      expect(cubit.state.visibleSpots, isEmpty);
      expect(cubit.state.minX, 0);
      expect(cubit.state.maxX, 0);
      expect(cubit.state.minY, 0);
      expect(cubit.state.maxY, 1);
    });

    test('all-period populates visibleSpots scaled by 100 and adds 10% Y-padding', () {
      final prices = [
        _pp(DateTime.utc(2026, 1, 1), 10000), // 100.00
        _pp(DateTime.utc(2026, 2, 1), 12000), // 120.00
        _pp(DateTime.utc(2026, 3, 1), 11000), // 110.00
      ];

      final cubit = PriceChartCubit(prices);

      expect(cubit.state.visibleSpots, hasLength(3));
      expect(cubit.state.visibleSpots.first.y, 100.0);
      expect(cubit.state.visibleSpots.last.y, 110.0);
      // Y range: min 100, max 120 → padding (120-100)*0.1 = 2.
      expect(cubit.state.minY, closeTo(98.0, 1e-9));
      expect(cubit.state.maxY, closeTo(122.0, 1e-9));
    });

    test('selectPeriod to the same period is a no-op (no emit)', () async {
      final cubit = PriceChartCubit([_pp(DateTime.utc(2026, 1, 1), 1000)]);
      final emitted = <PriceChartState>[];
      final sub = cubit.stream.listen(emitted.add);

      cubit.selectPeriod(TimePeriod.all);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(emitted, isEmpty);
    });

    test('selectPeriod to oneWeek filters to spots within the 7-day window', () {
      final now = DateTime.now();
      final oldPoint = _pp(now.subtract(const Duration(days: 60)), 5000);
      final recentPoint = _pp(now.subtract(const Duration(days: 2)), 6000);

      final cubit = PriceChartCubit([oldPoint, recentPoint]);
      cubit.selectPeriod(TimePeriod.oneWeek);

      expect(cubit.state.selectedPeriod, TimePeriod.oneWeek);
      // Only the recent point falls within the last 7 days.
      expect(cubit.state.visibleSpots, hasLength(1));
      expect(cubit.state.visibleSpots.first.y, 60.0);
    });
  });
}
