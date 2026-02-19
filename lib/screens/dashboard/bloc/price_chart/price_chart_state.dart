import 'package:equatable/equatable.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:realunit_wallet/screens/dashboard/models/time_period.dart';

class PriceChartState extends Equatable {
  const PriceChartState({
    required this.selectedPeriod,
    required this.visibleSpots,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  final TimePeriod selectedPeriod;
  final List<FlSpot> visibleSpots;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  @override
  List<Object?> get props => [selectedPeriod, visibleSpots, minX, maxX, minY, maxY];

  PriceChartState copyWith({
    TimePeriod? selectedPeriod,
    List<FlSpot>? visibleSpots,
    double? minX,
    double? maxX,
    double? minY,
    double? maxY,
  }) {
    return PriceChartState(
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      visibleSpots: visibleSpots ?? this.visibleSpots,
      minX: minX ?? this.minX,
      maxX: maxX ?? this.maxX,
      minY: minY ?? this.minY,
      maxY: maxY ?? this.maxY,
    );
  }
}
