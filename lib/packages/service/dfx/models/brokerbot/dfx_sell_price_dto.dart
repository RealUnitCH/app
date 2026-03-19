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
    return BrokerbotSellPriceDto(
      shares: (json['shares'] as num).toInt(),
      pricePerShare: (json['pricePerShare'] as num).toDouble(),
      estimatedAmount: (json['estimatedAmount'] as num).toDouble(),
      currency: json['currency'] as String,
    );
  }
}
