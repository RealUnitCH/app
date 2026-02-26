part of 'dashboard_bloc.dart';

class DashboardState extends Equatable {
  final BigInt price;
  final List<PricePoint> priceChart;
  final List<PortfolioValuePoint> portfolioHistory;
  final Currency currency;

  const DashboardState({
    required this.price,
    required this.priceChart,
    required this.portfolioHistory,
    required this.currency,
  });

  @override
  List<Object?> get props => [price, priceChart, portfolioHistory, currency];

  DashboardState copyWith({
    BigInt? price,
    List<PricePoint>? priceChart,
    List<PortfolioValuePoint>? portfolioHistory,
    Currency? currency,
  }) => DashboardState(
    price: price ?? this.price,
    priceChart: priceChart ?? this.priceChart,
    portfolioHistory: portfolioHistory ?? this.portfolioHistory,
    currency: currency ?? this.currency,
  );
}
