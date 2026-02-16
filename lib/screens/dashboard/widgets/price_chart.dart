import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:realunit_wallet/models/price_point.dart';
import 'package:realunit_wallet/packages/utils/format_fixed.dart';
import 'package:realunit_wallet/screens/dashboard/models/time_period.dart';
import 'package:realunit_wallet/screens/dashboard/widgets/time_period_button.dart';
import 'package:realunit_wallet/styles/colors.dart';

class PriceChart extends StatefulWidget {
  const PriceChart({
    super.key,
    required this.prices,
  });

  final List<PricePoint> prices;

  @override
  State<PriceChart> createState() => _PriceChartState();
}

class _PriceChartState extends State<PriceChart> {
  static const int horizontalDivisions = 5;

  TimePeriod selectedPeriod = TimePeriod.oneMonth;

  late List<FlSpot> _visibleSpots;
  late double _minY;
  late double _maxY;
  late double _minX;
  late double _maxX;

  @override
  Widget build(BuildContext context) {
    _prepareChartData();

    return Column(
      spacing: 16.0,
      children: [
        SizedBox(
          height: 135,
          child: LineChart(_buildChartData(), duration: Duration.zero),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: TimePeriod.values.map((period) {
              final isSelected = selectedPeriod == period;
              return Expanded(
                child: TimePeriodButton(
                  period.name,
                  isSelected: isSelected,
                  onTap: () => setState(() => selectedPeriod = period),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _prepareChartData() {
    if (widget.prices.isEmpty) {
      _visibleSpots = [];
      _minY = 0;
      _maxY = 1;
      _minX = DateTime.now().millisecondsSinceEpoch.toDouble();
      _maxX = _minX;
      return;
    }

    final now = DateTime.now();

    // Calculate minX and maxXbased on selected period
    _minX = switch (selectedPeriod) {
      TimePeriod.oneWeek => DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 7)).millisecondsSinceEpoch.toDouble(),
      TimePeriod.oneMonth => DateTime(
        now.year,
        now.month - 1,
        now.day,
      ).millisecondsSinceEpoch.toDouble(),
      TimePeriod.threeMonths => DateTime(
        now.year,
        now.month - 3,
        now.day,
      ).millisecondsSinceEpoch.toDouble(),
      TimePeriod.oneYear => DateTime(
        now.year - 1,
        now.month,
        now.day,
      ).millisecondsSinceEpoch.toDouble(),
      TimePeriod.all => widget.prices.first.time.millisecondsSinceEpoch.toDouble(),
    };
    _maxX = widget.prices.last.time.millisecondsSinceEpoch.toDouble();

    // Filter price points to those within the selected time period (between minX and maxX)
    _visibleSpots = widget.prices
        .where(
          (pricePoint) =>
              pricePoint.time.millisecondsSinceEpoch >= _minX &&
              pricePoint.time.millisecondsSinceEpoch <= _maxX,
        )
        .map(
          (pricePoint) => FlSpot(
            pricePoint.time.millisecondsSinceEpoch.toDouble(),
            double.parse(formatFixed(pricePoint.price, 2)),
          ),
        )
        .toList();

    // Calculate minY and maxY from the visible spots, with some padding (10%)
    double min = _visibleSpots.first.y;
    double max = _visibleSpots.first.y;

    for (final spot in _visibleSpots) {
      if (spot.y < min) min = spot.y;
      if (spot.y > max) max = spot.y;
    }

    final padding = (max - min) * 0.1;

    _minY = min - padding;
    _maxY = max + padding;
  }

  LineChartData _buildChartData() {
    return LineChartData(
      minX: _minX,
      maxX: _maxX,
      minY: _minY,
      maxY: _maxY,
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      extraLinesData: ExtraLinesData(
        horizontalLines: _buildHorizontalLines(),
      ),
      lineBarsData: [_buildLineBar()],
      lineTouchData: _buildTouchData(),
    );
  }

  List<HorizontalLine> _buildHorizontalLines() {
    return List.generate(horizontalDivisions + 1, (index) {
      final ratio = index / horizontalDivisions;
      final y = _maxY - ((_maxY - _minY) * ratio);

      final showLabel = index == 0 || index == horizontalDivisions;

      return HorizontalLine(
        y: y,
        color: RealUnitColors.neutral400,
        dashArray: const [1, 3],
        strokeWidth: 1,
        label: showLabel
            ? HorizontalLineLabel(
                show: true,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20, top: -16),
                style: const TextStyle(
                  color: RealUnitColors.neutral400,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
                labelResolver: (line) => formatFixed(
                  BigInt.from(line.y * 100),
                  2,
                ),
              )
            : null,
      );
    });
  }

  LineChartBarData _buildLineBar() {
    return LineChartBarData(
      spots: _visibleSpots,
      isCurved: true,
      color: RealUnitColors.darkBlue,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(185, 221, 241, 0.6),
            Color.fromRGBO(185, 221, 241, 0.2),
            Color.fromRGBO(185, 221, 241, 0.0),
          ],
          stops: [0.0, 0.3638, 1.0],
        ),
      ),
    );
  }

  LineTouchData _buildTouchData() {
    return LineTouchData(
      enabled: true,
      touchTooltipData: LineTouchTooltipData(
        fitInsideHorizontally: true,
        tooltipMargin: 0,
        getTooltipItems: (touchedSpots) => touchedSpots.map((touchedSpot) {
          final date = DateTime.fromMillisecondsSinceEpoch(touchedSpot.x.toInt());
          final price = touchedSpot.y;
          return LineTooltipItem(
            '${date.day}.${date.month}.${date.year}\n'
            '${formatFixed(BigInt.from(price * 100), 2)}',
            const TextStyle(
              color: RealUnitColors.neutral500,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          );
        }).toList(),
        getTooltipColor: (_) => Colors.transparent,
      ),
      getTouchLineStart: (barData, spotIndex) => -double.infinity,
      getTouchLineEnd: (barData, spotIndex) => double.infinity,
      getTouchedSpotIndicator: (barData, spotIndexes) => spotIndexes.map((index) {
        return const TouchedSpotIndicatorData(
          FlLine(color: RealUnitColors.neutral200, dashArray: [4, 4]),
          FlDotData(show: true),
        );
      }).toList(),
    );
  }
}
