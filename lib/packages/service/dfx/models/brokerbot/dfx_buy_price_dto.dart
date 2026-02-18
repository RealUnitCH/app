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
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      final s = value.toString().replaceAll(',', '.').trim();
      return double.tryParse(s) ?? 0.0;
    }

    return BrokerbotBuyPriceDto(
      totalCost: parseDouble(json['totalPrice']),
      pricePerShare: parseDouble(json['pricePerShare']),
      availableShares: int.parse(json['availableShares'].toString()),
    );
  }
}
