part of 'dashboard_bloc.dart';

class DashboardState extends Equatable {
  final BigInt price;
  final List<PricePoint> priceChart;

  const DashboardState({required this.price, required this.priceChart});

  @override
  List<Object?> get props => [price, priceChart];

  DashboardState copyWith({
    BigInt? price,
    List<PricePoint>? priceChart,
  }) =>
      DashboardState(
        price: price ?? this.price,
        priceChart: priceChart ?? this.priceChart,
      );
}
