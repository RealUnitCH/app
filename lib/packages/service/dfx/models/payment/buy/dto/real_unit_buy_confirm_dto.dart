class RealUnitBuyConfirmDto {
  final String reference;

  const RealUnitBuyConfirmDto({required this.reference});

  factory RealUnitBuyConfirmDto.fromJson(Map<String, dynamic> json) {
    return RealUnitBuyConfirmDto(
      reference: json['reference'] as String,
    );
  }
}
