class BrokerbotBuySharesDto {
  final int shares;
  final double pricePerShare;
  final int availableShares;

  BrokerbotBuySharesDto({
    required this.shares,
    required this.pricePerShare,
    required this.availableShares,
  });

  factory BrokerbotBuySharesDto.fromJson(Map<String, dynamic> json) {
    return BrokerbotBuySharesDto(
      shares: (json['shares'] as num).toInt(),
      pricePerShare: (json['pricePerShare'] as num).toDouble(),
      availableShares: (json['availableShares'] as num).toInt(),
    );
  }
}
