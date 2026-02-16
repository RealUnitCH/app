import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:realunit_wallet/models/price_point.dart';
import 'package:realunit_wallet/packages/utils/format_fixed.dart';
import 'package:realunit_wallet/styles/colors.dart';

enum TimePeriod {
  oneWeek,
  oneMonth,
  threeMonths,
  oneYear,
  all
  ;

  String get name {
    switch (this) {
      case TimePeriod.oneWeek:
        return '1W';
      case TimePeriod.oneMonth:
        return '1M';
      case TimePeriod.threeMonths:
        return '3M';
      case TimePeriod.oneYear:
        return '1Y';
      case TimePeriod.all:
        return 'ALL';
    }
  }
}

class PriceChart extends StatefulWidget {
  const PriceChart({
    super.key,
    required this.prices,
    this.startDate = 1742428800,
  });

  final List<PricePoint> prices;
  final int startDate;

  @override
  State<PriceChart> createState() => _PriceChartState();
}

class _PriceChartState extends State<PriceChart> {
  static const int horizontalDivisions = 5;
  TimePeriod selectedPeriod = TimePeriod.oneMonth;

  @override
  Widget build(BuildContext context) => Column(
    spacing: 16.0,
    children: [
      SizedBox(
        height: 135,
        child: LineChart(data, duration: Duration.zero),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
          children: TimePeriod.values.map((period) {
            final isSelected = selectedPeriod == period;
            return Expanded(
              child: _TimePeriodButton(
                period.name.toUpperCase(),
                isSelected: isSelected,
                onTap: () => setState(() => selectedPeriod = period),
              ),
            );
          }).toList(),
        ),
      ),
    ],
  );

  LineChartData get data => LineChartData(
    minX: minX(selectedPeriod),
    maxX: maxX(),
    minY: minY,
    maxY: maxY,
    extraLinesData: ExtraLinesData(
      horizontalLines: List.generate(
        horizontalDivisions + 1,
        (index) {
          final ratio = index / horizontalDivisions;
          final y = maxY - ((maxY - minY) * ratio);

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
                    padding: const EdgeInsets.only(right: 20),
                    style: const TextStyle(
                      color: RealUnitColors.neutral400,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    labelResolver: (line) => formatFixed(
                      BigInt.from(line.y * 100),
                      2,
                      trimZeros: false,
                    ),
                  )
                : null,
          );
        },
      ),
    ),
    lineBarsData: [lineChartBarData],
    lineTouchData: LineTouchData(
      enabled: true,
      touchTooltipData: LineTouchTooltipData(
        fitInsideHorizontally: true,
        tooltipMargin: 0.0,
        getTooltipItems: (touchedSpots) => touchedSpots.map((touchedSpot) {
          final date = DateTime.fromMillisecondsSinceEpoch(touchedSpot.x.toInt());
          final price = touchedSpot.y;
          return LineTooltipItem(
            '${date.day}.${date.month}.${date.year}\n${formatFixed(BigInt.from(price * 100), 2, trimZeros: false)}',
            const TextStyle(
              color: RealUnitColors.neutral500,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          );
        }).toList(),
        getTooltipColor: (touchedSpot) => Colors.transparent,
      ),
      getTouchLineStart: (barData, spotIndex) => -double.infinity,
      getTouchLineEnd: (barData, spotIndex) => double.infinity,
      getTouchedSpotIndicator: (barData, spotIndexes) => spotIndexes.map((index) {
        return const TouchedSpotIndicatorData(
          FlLine(color: RealUnitColors.neutral200, dashArray: [4, 4]),
          FlDotData(show: true),
        );
      }).toList(),
    ),
    gridData: const FlGridData(show: false),
    titlesData: const FlTitlesData(show: false),
    borderData: FlBorderData(show: false),
  );

  LineChartBarData get lineChartBarData => LineChartBarData(
    isCurved: true,
    color: RealUnitColors.darkBlue,
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
    barWidth: 2,
    isStrokeCapRound: true,
    dotData: const FlDotData(show: false),
    spots: widget.prices
        .map(
          (priceSpot) => FlSpot(
            priceSpot.time.millisecondsSinceEpoch.toDouble(),
            double.parse(formatFixed(priceSpot.price, 2)),
          ),
        )
        .toList(),
  );

  double minX(TimePeriod period) {
    final now = DateTime.now();

    switch (period) {
      case TimePeriod.oneMonth:
        return DateTime(now.year, now.month - 1, now.day).millisecondsSinceEpoch.toDouble();
      case TimePeriod.threeMonths:
        return DateTime(now.year, now.month - 3, now.day).millisecondsSinceEpoch.toDouble();
      case TimePeriod.oneWeek:
        return now.subtract(const Duration(days: 7)).millisecondsSinceEpoch.toDouble();
      case TimePeriod.oneYear:
        return DateTime(now.year - 1, now.month, now.day).millisecondsSinceEpoch.toDouble();
      case TimePeriod.all:
        return widget.prices.first.time.millisecondsSinceEpoch.toDouble();
    }
  }

  double maxX() {
    if (widget.prices.isEmpty) {
      return DateTime.now().millisecondsSinceEpoch.toDouble();
    }

    return widget.prices.last.time.millisecondsSinceEpoch.toDouble();
  }

  List<FlSpot> get visibleSpots {
    if (widget.prices.isEmpty) return [];

    return widget.prices
        .map(
          (e) => FlSpot(
            e.time.millisecondsSinceEpoch.toDouble(),
            double.parse(formatFixed(e.price, 2)),
          ),
        )
        .where((spot) => spot.x >= minX(selectedPeriod) && spot.x <= maxX())
        .toList();
  }

  double get minY {
    final ys = visibleSpots.map((e) => e.y);
    final min = ys.reduce((a, b) => a < b ? a : b);
    final max = ys.reduce((a, b) => a > b ? a : b);

    final padding = (max - min) * 0.1; // 10% padding
    return min - padding;
  }

  double get maxY {
    final ys = visibleSpots.map((e) => e.y);
    final min = ys.reduce((a, b) => a < b ? a : b);
    final max = ys.reduce((a, b) => a > b ? a : b);

    final padding = (max - min) * 0.1;
    return max + padding;
  }
}

class _TimePeriodButton extends StatelessWidget {
  final String label;
  final void Function()? onTap;
  final bool isSelected;

  const _TimePeriodButton(
    this.label, {
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? RealUnitColors.realUnitBlue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? RealUnitColors.realUnitBlue : RealUnitColors.neutral400,
            height: 18 / 14,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
