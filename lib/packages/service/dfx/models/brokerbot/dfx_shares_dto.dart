class BrokerbotSharesDto {
  final int shares;
  final double pricePerShare;
  final int availableShares;

  BrokerbotSharesDto({
    required this.shares,
    required this.pricePerShare,
    required this.availableShares,
  });

  factory BrokerbotSharesDto.fromJson(Map<String, dynamic> json) {
    return BrokerbotSharesDto(
      shares: int.parse(json['shares'].toString()),
      pricePerShare: double.parse(json['pricePerShare'].toString()),
      availableShares: int.parse(json['availableShares'].toString()),
    );
  }
}
