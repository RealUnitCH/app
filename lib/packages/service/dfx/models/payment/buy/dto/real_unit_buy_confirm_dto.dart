class RealUnitBuyConfirmDto {
  final String reference;
  final String remittanceInfo;
  final String? paymentRequest;

  const RealUnitBuyConfirmDto({
    required this.reference,
    required this.remittanceInfo,
    this.paymentRequest,
  });

  factory RealUnitBuyConfirmDto.fromJson(Map<String, dynamic> json) {
    return RealUnitBuyConfirmDto(
      reference: json['reference'] as String,
      remittanceInfo: json['remittanceInfo'] as String,
      paymentRequest: json['paymentRequest'] as String?,
    );
  }
}
