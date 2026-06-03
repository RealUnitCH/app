/// Public payment-link read response of `GET /v1/lnurlp/:id` (on api.dfx.swiss,
/// no auth). Carries the requested fiat amount and the active quote the app
/// needs to size the swap and later settle the payment. Only the fields the pay
/// flow consumes are mapped.
class LnurlpPaymentDto {
  final LnurlpRequestedAmountDto requestedAmount;
  final LnurlpQuoteDto quote;
  final String? recipient;

  /// Per-method/chain transfer amounts. The Ethereum entry lists the exact ZCHF
  /// amount the app must transfer; the app does not compute it locally.
  final List<LnurlpTransferAmountDto> transferAmounts;

  const LnurlpPaymentDto({
    required this.requestedAmount,
    required this.quote,
    required this.transferAmounts,
    this.recipient,
  });

  factory LnurlpPaymentDto.fromJson(Map<String, dynamic> json) {
    final transfers = (json['transferAmounts'] as List<dynamic>?) ?? const [];
    return LnurlpPaymentDto(
      requestedAmount: LnurlpRequestedAmountDto.fromJson(
        json['requestedAmount'] as Map<String, dynamic>,
      ),
      quote: LnurlpQuoteDto.fromJson(json['quote'] as Map<String, dynamic>),
      recipient: json['recipient'] as String?,
      transferAmounts: transfers
          .map((e) => LnurlpTransferAmountDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LnurlpRequestedAmountDto {
  final String asset;
  final double amount;

  const LnurlpRequestedAmountDto({required this.asset, required this.amount});

  factory LnurlpRequestedAmountDto.fromJson(Map<String, dynamic> json) {
    return LnurlpRequestedAmountDto(
      asset: json['asset'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

class LnurlpQuoteDto {
  final String id;
  final DateTime expiration;

  const LnurlpQuoteDto({required this.id, required this.expiration});

  factory LnurlpQuoteDto.fromJson(Map<String, dynamic> json) {
    return LnurlpQuoteDto(
      id: json['id'] as String,
      expiration: DateTime.parse(json['expiration'] as String),
    );
  }
}

class LnurlpTransferAmountDto {
  final String method;
  final List<LnurlpTransferAssetDto> assets;

  const LnurlpTransferAmountDto({required this.method, required this.assets});

  factory LnurlpTransferAmountDto.fromJson(Map<String, dynamic> json) {
    final assets = (json['assets'] as List<dynamic>?) ?? const [];
    return LnurlpTransferAmountDto(
      method: json['method'] as String,
      assets: assets
          .map((e) => LnurlpTransferAssetDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LnurlpTransferAssetDto {
  final String asset;
  final double amount;

  const LnurlpTransferAssetDto({required this.asset, required this.amount});

  factory LnurlpTransferAssetDto.fromJson(Map<String, dynamic> json) {
    return LnurlpTransferAssetDto(
      asset: json['asset'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }
}
