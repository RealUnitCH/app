class PriceStep {
  final String source;
  final String from;
  final String to;
  final double price;
  final DateTime timestamp;

  const PriceStep({
    required this.source,
    required this.from,
    required this.to,
    required this.price,
    required this.timestamp,
  });

  factory PriceStep.fromJson(Map<String, dynamic> json) {
    return PriceStep(
      source: json['source'] as String,
      from: json['from'] as String,
      to: json['to'] as String,
      price: (json['price'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
