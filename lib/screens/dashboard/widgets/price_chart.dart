import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:realunit_wallet/models/price_point.dart';
import 'package:realunit_wallet/packages/utils/format_fixed.dart';
import 'package:realunit_wallet/styles/colors.dart';

class PriceChart extends StatelessWidget {
  const PriceChart(
      {super.key, required this.prices, this.startDate = 1742428800});

  final List<PricePoint> prices;
  final int startDate;

  LineChartData get data => LineChartData(
        lineTouchData: LineTouchData(handleBuiltInTouches: false),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(color: Colors.transparent),
            left: BorderSide(color: Colors.transparent),
            right: BorderSide(color: Colors.transparent),
            top: BorderSide(color: Colors.transparent),
          ),
        ),
        lineBarsData: [lineChartBarData],
      );

  LineChartBarData get lineChartBarData => LineChartBarData(
        isCurved: true,
        color: RealUnitColors.darkBlue,
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(153, 185, 221, 241),
              Color.fromARGB(0, 185, 221, 241)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        spots: prices
            .map((priceSpot) => FlSpot(
                  priceSpot.time.millisecondsSinceEpoch.toDouble(),
                  double.parse(formatFixed(priceSpot.price, 2)),
                ))
            .toList(),
      );

  @override
  Widget build(BuildContext context) => LineChart(data);
}
