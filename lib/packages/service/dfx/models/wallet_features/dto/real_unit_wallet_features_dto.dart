class RealUnitWalletFeaturesDto {
  final bool pay;
  final bool send;
  final bool promoCode;
  final bool referral;

  const RealUnitWalletFeaturesDto({
    this.pay = false,
    this.send = false,
    this.promoCode = false,
    this.referral = false,
  });

  factory RealUnitWalletFeaturesDto.fromJson(Map<String, dynamic> json) {
    return RealUnitWalletFeaturesDto(
      pay: json['pay'] as bool? ?? false,
      send: json['send'] as bool? ?? false,
      promoCode: json['promoCode'] as bool? ?? false,
      referral: json['referral'] as bool? ?? false,
    );
  }
}
