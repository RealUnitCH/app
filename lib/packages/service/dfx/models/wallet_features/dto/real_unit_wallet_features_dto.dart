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
      pay: json['pay'] == true,
      send: json['send'] == true,
      promoCode: json['promoCode'] == true,
      referral: json['referral'] == true,
    );
  }
}
