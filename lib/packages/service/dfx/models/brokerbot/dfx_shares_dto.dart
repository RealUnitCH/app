class BrokerbotSharesDto {
  final double shares;
  final double pricePerShare;

  BrokerbotSharesDto({
    required this.shares,
    required this.pricePerShare,
  });

  factory BrokerbotSharesDto.fromJson(Map<String, dynamic> json) {
    return BrokerbotSharesDto(
      shares: double.parse(json['shares'].toString()),
      pricePerShare: double.parse(json['pricePerShare'].toString()),
    );
  }
}
