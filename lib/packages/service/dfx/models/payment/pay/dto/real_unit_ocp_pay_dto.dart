/// Request body for `PUT /v1/realunit/pay/unsigned-transaction`. References the
/// scanned payment link, its active quote and the confirmed swap quote so the
/// backend resolves recipient and exact ZCHF amount against that same swap.
class RealUnitOcpPayDto {
  final String paymentLinkId;
  final String quoteId;
  final int swapRequestId;

  const RealUnitOcpPayDto({
    required this.paymentLinkId,
    required this.quoteId,
    required this.swapRequestId,
  });

  Map<String, dynamic> toJson() => {
    'paymentLinkId': paymentLinkId,
    'quoteId': quoteId,
    'swapRequestId': swapRequestId,
  };
}
