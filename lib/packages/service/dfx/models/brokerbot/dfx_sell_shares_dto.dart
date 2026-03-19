class BrokerbotSellSharesDto {
  final double targetAmount;
  final int shares;
  final double pricePerShare;
  final String currency;

  BrokerbotSellSharesDto({
    required this.targetAmount,
    required this.shares,
    required this.pricePerShare,
    required this.currency,
  });

  factory BrokerbotSellSharesDto.fromJson(Map<String, dynamic> json) {
    return BrokerbotSellSharesDto(
      targetAmount: (json['targetAmount'] as num).toDouble(),
      shares: (json['shares'] as num).toInt(),
      pricePerShare: (json['pricePerShare'] as num).toDouble(),
      currency: json['currency'] as String,
    );
  }
}
