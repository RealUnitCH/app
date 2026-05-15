import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/models/portfolio_value_point.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/portfolio_chart/portfolio_chart_cubit.dart';
import 'package:realunit_wallet/screens/dashboard/models/time_period.dart';

PortfolioValuePoint _pt(DateTime time, int rappen) => PortfolioValuePoint(
      value: BigInt.from(rappen),
      balance: BigInt.one,
      time: time,
    );

void main() {
  group('$PortfolioChartCubit', () {
    test('empty input yields the zero-window initial-shape state', () {
      final cubit = PortfolioChartCubit(const []);

      expect(cubit.state.visibleSpots, isEmpty);
      expect(cubit.state.minX, 0);
      expect(cubit.state.maxX, 0);
      expect(cubit.state.minY, 0);
      expect(cubit.state.maxY, 1);
      expect(cubit.state.horizontalLineValues, isEmpty);
    });

    test('all-period populates visibleSpots scaled by 100', () {
      final points = [
        _pt(DateTime.utc(2026, 1, 1), 50000), // 500.00
        _pt(DateTime.utc(2026, 2, 1), 60000), // 600.00
      ];

      final cubit = PortfolioChartCubit(points);

      expect(cubit.state.visibleSpots, hasLength(2));
      expect(cubit.state.visibleSpots.first.y, 500.0);
      expect(cubit.state.visibleSpots.last.y, 600.0);
      // 6 horizontal lines are always produced when there is data.
      expect(cubit.state.horizontalLineValues, hasLength(6));
      // minY / maxY come from the first/last horizontal line.
      expect(cubit.state.minY, cubit.state.horizontalLineValues.first);
      expect(cubit.state.maxY, cubit.state.horizontalLineValues.last);
    });

    test('flat-value series still spreads lines via the 5% floor (no Y-collapse)', () {
      // When all values are equal, the cubit floors the padded deviation at
      // `average * 0.05` so the chart still has a visible Y-range instead of
      // collapsing to a single horizontal line.
      final points = [
        _pt(DateTime.utc(2026, 1, 1), 10000),
        _pt(DateTime.utc(2026, 2, 1), 10000),
        _pt(DateTime.utc(2026, 3, 1), 10000),
      ];

      final cubit = PortfolioChartCubit(points);

      expect(cubit.state.horizontalLineValues, hasLength(6));
      // average 100 → floor 5 → rawInterval 2 → niceNumber 2 → bottom 94.
      expect(
        cubit.state.horizontalLineValues,
        [94.0, 96.0, 98.0, 100.0, 102.0, 104.0],
      );
      expect(cubit.state.minY, 94.0);
      expect(cubit.state.maxY, 104.0);
    });

    test('selectPeriod to the same period is a no-op (no emit)', () async {
      final cubit = PortfolioChartCubit([_pt(DateTime.utc(2026, 1, 1), 5000)]);
      final emitted = [];
      final sub = cubit.stream.listen(emitted.add);

      cubit.selectPeriod(TimePeriod.all);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(emitted, isEmpty);
    });

    test('selectPeriod to oneWeek narrows visibleSpots to the 7-day window', () {
      final now = DateTime.now();
      final old = _pt(now.subtract(const Duration(days: 60)), 5000);
      final recent = _pt(now.subtract(const Duration(days: 2)), 6000);

      final cubit = PortfolioChartCubit([old, recent]);
      cubit.selectPeriod(TimePeriod.oneWeek);

      expect(cubit.state.selectedPeriod, TimePeriod.oneWeek);
      expect(cubit.state.visibleSpots, hasLength(1));
      expect(cubit.state.visibleSpots.single.y, 60.0);
    });
  });
}
