class RealUnitBuyConfirmDto {
  final String reference;
  // Backward compatible: the current API does not yet return these. Once the
  // API finalises the payment instruction at confirm time it sends
  // `remittanceInfo` (the designated purpose of payment, equal to `reference`)
  // and `paymentRequest` (the QR encoding it). Until then they are null — the
  // app falls back to `reference` and shows no QR.
  final String? remittanceInfo;
  final String? paymentRequest;

  const RealUnitBuyConfirmDto({
    required this.reference,
    this.remittanceInfo,
    this.paymentRequest,
  });

  factory RealUnitBuyConfirmDto.fromJson(Map<String, dynamic> json) {
    return RealUnitBuyConfirmDto(
      reference: json['reference'] as String,
      remittanceInfo: json['remittanceInfo'] as String?,
      paymentRequest: json['paymentRequest'] as String?,
    );
  }
}
