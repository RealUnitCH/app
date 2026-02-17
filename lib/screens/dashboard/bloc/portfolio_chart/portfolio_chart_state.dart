part of 'portfolio_chart_cubit.dart';

class PortfolioChartState extends Equatable {
  const PortfolioChartState({
    required this.selectedPeriod,
    required this.visibleSpots,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.horizontalLineValues,
  });

  final TimePeriod selectedPeriod;
  final List<FlSpot> visibleSpots;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  /// Rounded Y values for horizontal grid lines (e.g., [300, 400, 500] for values 300-500)
  final List<double> horizontalLineValues;

  @override
  List<Object?> get props => [selectedPeriod, visibleSpots, minX, maxX, minY, maxY, horizontalLineValues];

  PortfolioChartState copyWith({
    TimePeriod? selectedPeriod,
    List<FlSpot>? visibleSpots,
    double? minX,
    double? maxX,
    double? minY,
    double? maxY,
    List<double>? horizontalLineValues,
  }) {
    return PortfolioChartState(
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      visibleSpots: visibleSpots ?? this.visibleSpots,
      minX: minX ?? this.minX,
      maxX: maxX ?? this.maxX,
      minY: minY ?? this.minY,
      maxY: maxY ?? this.maxY,
      horizontalLineValues: horizontalLineValues ?? this.horizontalLineValues,
    );
  }
}
