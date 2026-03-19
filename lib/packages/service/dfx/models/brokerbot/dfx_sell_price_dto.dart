class BrokerbotSellPriceDto {
  final int shares;
  final double estimatedAmount;
  final double pricePerShare;
  final String currency;

  BrokerbotSellPriceDto({
    required this.shares,
    required this.estimatedAmount,
    required this.pricePerShare,
    required this.currency,
  });

  factory BrokerbotSellPriceDto.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      final s = value.toString().replaceAll(',', '.').trim();
      return double.tryParse(s) ?? 0.0;
    }

    return BrokerbotSellPriceDto(
      shares: int.parse(json['shares'].toString()),
      pricePerShare: parseDouble(json['pricePerShare']),
      estimatedAmount: parseDouble(json['estimatedAmount']),
      currency: json['currency'] as String,
    );
  }
}
