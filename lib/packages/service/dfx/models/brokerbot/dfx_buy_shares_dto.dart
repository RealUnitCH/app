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
      shares: int.parse(json['shares'].toString()),
      pricePerShare: double.parse(json['pricePerShare'].toString()),
      availableShares: int.parse(json['availableShares'].toString()),
    );
  }
}
