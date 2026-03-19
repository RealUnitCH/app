class BrokerbotBuyPriceDto {
  final double totalCost;
  final double pricePerShare;
  final int availableShares;

  BrokerbotBuyPriceDto({
    required this.totalCost,
    required this.pricePerShare,
    required this.availableShares,
  });

  factory BrokerbotBuyPriceDto.fromJson(Map<String, dynamic> json) {
    return BrokerbotBuyPriceDto(
      totalCost: (json['totalPrice'] as num).toDouble(),
      pricePerShare: (json['pricePerShare'] as num).toDouble(),
      availableShares: (json['availableShares'] as num).toInt(),
    );
  }
}
