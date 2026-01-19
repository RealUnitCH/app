part of 'dashboard_bloc.dart';

class DashboardState extends Equatable {
  final BigInt price;
  final List<PricePoint> priceChart;
  final Currency currency;

  const DashboardState({
    required this.price,
    required this.priceChart,
    required this.currency,
  });

  @override
  List<Object?> get props => [price, priceChart, currency];

  DashboardState copyWith({
    BigInt? price,
    List<PricePoint>? priceChart,
    Currency? currency,
  }) =>
      DashboardState(
        price: price ?? this.price,
        priceChart: priceChart ?? this.priceChart,
        currency: currency ?? this.currency,
      );
}
