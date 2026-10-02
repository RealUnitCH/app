/// Request body for `PUT /v1/realunit/pay/submit`. The signed-tx envelope
/// (`unsignedTx` + `r`/`s`/`v`) mirrors the sell/swap broadcast shape, plus the
/// payment-link/quote/swap references so the backend forwards the hex into the
/// lnurlp settlement path against the confirmed swap quote.
class RealUnitOcpPaySubmitDto {
  final String unsignedTx;
  final String r;
  final String s;
  final int v;
  final String paymentLinkId;
  final String quoteId;
  final int swapRequestId;

  const RealUnitOcpPaySubmitDto({
    required this.unsignedTx,
    required this.r,
    required this.s,
    required this.v,
    required this.paymentLinkId,
    required this.quoteId,
    required this.swapRequestId,
  });

  Map<String, dynamic> toJson() => {
    'unsignedTx': unsignedTx,
    'r': r,
    's': s,
    'v': v,
    'paymentLinkId': paymentLinkId,
    'quoteId': quoteId,
    'swapRequestId': swapRequestId,
  };
}
