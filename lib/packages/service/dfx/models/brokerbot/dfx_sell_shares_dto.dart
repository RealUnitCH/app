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
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      final s = value.toString().replaceAll(',', '.').trim();
      return double.tryParse(s) ?? 0.0;
    }

    return BrokerbotSellSharesDto(
      targetAmount: parseDouble(json['targetAmount']),
      shares: int.parse(json['shares'].toString()),
      pricePerShare: parseDouble(json['pricePerShare']),
      currency: json['currency'] as String,
    );
  }
}
