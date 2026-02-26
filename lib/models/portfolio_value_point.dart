class PortfolioValuePoint {
  /// Portfolio value in rappen/cents
  final BigInt value;

  /// RealU balance
  final BigInt balance;
  final DateTime time;

  const PortfolioValuePoint({
    required this.value,
    required this.balance,
    required this.time,
  });
}
