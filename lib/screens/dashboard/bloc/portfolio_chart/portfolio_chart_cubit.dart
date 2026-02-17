import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/models/portfolio_value_point.dart';
import 'package:realunit_wallet/packages/utils/format_fixed.dart';
import 'package:realunit_wallet/screens/dashboard/models/time_period.dart';

part 'portfolio_chart_state.dart';

class PortfolioChartCubit extends Cubit<PortfolioChartState> {
  PortfolioChartCubit(this._prices)
    : super(
        const PortfolioChartState(
          selectedPeriod: TimePeriod.threeMonths,
          visibleSpots: [],
          minX: 0,
          maxX: 0,
          minY: 0,
          maxY: 1,
          horizontalLineValues: [],
        ),
      ) {
    _calculateChartData();
  }

  final List<PortfolioValuePoint> _prices;

  void selectPeriod(TimePeriod period) {
    if (period == state.selectedPeriod) return;
    emit(state.copyWith(selectedPeriod: period));
    _calculateChartData();
  }

  void _calculateChartData() {
    if (_prices.isEmpty) {
      emit(
        state.copyWith(
          visibleSpots: [],
          minX: 0,
          maxX: 0,
          minY: 0,
          maxY: 1,
          horizontalLineValues: [],
        ),
      );
      return;
    }

    final now = DateTime.now();

    // Calculate minX and maxXbased on selected period
    final firstPriceX = _prices.first.time.millisecondsSinceEpoch.toDouble();
    final startDate = switch (state.selectedPeriod) {
      TimePeriod.oneWeek => now.subtract(const Duration(days: 7)),
      TimePeriod.oneMonth => DateTime(
        now.year,
        now.month - 1,
        now.day,
      ),
      TimePeriod.threeMonths => DateTime(
        now.year,
        now.month - 3,
        now.day,
      ),
      TimePeriod.oneYear => DateTime(
        now.year - 1,
        now.month,
        now.day,
      ),
      TimePeriod.all => _prices.first.time,
    };
    final minX = math.max(
      startDate.millisecondsSinceEpoch.toDouble(),
      firstPriceX,
    );
    final maxX = _prices.last.time.millisecondsSinceEpoch.toDouble();

    // Filter price points to those within the selected time period (between minX and maxX)
    final visibleSpots = _prices
        .where(
          (p) => p.time.millisecondsSinceEpoch >= minX && p.time.millisecondsSinceEpoch <= maxX,
        )
        .map(
          (p) => FlSpot(
            p.time.millisecondsSinceEpoch.toDouble(),
            double.parse(formatFixed(p.value, 2)),
          ),
        )
        .toList();

    // Calculate minY and maxY from the visible spots
    var min = visibleSpots.first.y;
    var max = visibleSpots.first.y;

    for (final spot in visibleSpots) {
      if (spot.y < min) min = spot.y;
      if (spot.y > max) max = spot.y;
    }

    // Calculate nice rounded horizontal line values
    final horizontalLineValues = _calculateHorizontalLines(min, max);

    // Use the horizontal line values to determine minY and maxY with padding
    final minY = horizontalLineValues.first;
    final maxY = horizontalLineValues.last;

    emit(
      state.copyWith(
        visibleSpots: visibleSpots,
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        horizontalLineValues: horizontalLineValues,
      ),
    );
  }

  List<double> _calculateHorizontalLines(double min, double max) {
    if (max <= 0) return [0, 100, 200, 300, 400, 500];

    final ceiling = _getCeiling(max);

    final interval = ceiling / 5;

    return List.generate(6, (i) => i * interval);
  }

  double _getCeiling(double value) {
    if (value <= 500) return 500;

    double ceiling = 500;
    while (ceiling < value) {
      ceiling *= 2; // 500 → 1000
      if (ceiling >= value) break;
      ceiling *= 2; // 1000 → 2000
      if (ceiling >= value) break;
      ceiling *= 2.5; // 2000 → 5000
    }
    return ceiling;
  }
}
