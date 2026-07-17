/// Public payment-link read response of `GET /v1/lnurlp/:id` (on api.dfx.swiss,
/// no auth). Carries the requested fiat amount and the active quote the app
/// needs to size the swap and later settle the payment. Only the fields the pay
/// flow consumes are mapped.
///
/// The backend `recipient` field is mapped as [LnurlpRecipientDto?] (nullable
/// structured object). Only `name` and `city` are carried — the fields the
/// pay-quote screen displays. Everything else on the backend
/// `PaymentLinkRecipientDto` object is intentionally left unmapped. When the
/// merchant configured no recipient the field is absent and parses to null.
class LnurlpPaymentDto {
  final LnurlpRequestedAmountDto requestedAmount;
  final LnurlpQuoteDto quote;

  /// Per-method/chain transfer amounts. The Ethereum entry lists the exact ZCHF
  /// amount the app must transfer; the app does not compute it locally.
  final List<LnurlpTransferAmountDto> transferAmounts;

  final LnurlpRecipientDto? recipient;

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
      transferAmounts: transfers
          .map((e) => LnurlpTransferAmountDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      recipient: json['recipient'] == null
          ? null
          : LnurlpRecipientDto.fromJson(json['recipient'] as Map<String, dynamic>),
    );
  }
}

/// Merchant/recipient fields surfaced on the pay-quote screen. Only `name` and
/// `city` (from nested `address`) are mapped; other backend fields are unused.
class LnurlpRecipientDto {
  final String? name;
  final String? city;

  const LnurlpRecipientDto({this.name, this.city});

  factory LnurlpRecipientDto.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>?;
    return LnurlpRecipientDto(
      name: json['name'] as String?,
      city: address?['city'] as String?,
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
      amount: double.parse(json['amount'].toString()),
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

  /// Optional on the backend (`amount?`): the non-priced display path emits
  /// amount-less asset entries. Parsed as nullable so reading the whole quote
  /// never throws — the pay flow only requires the amount for the asset it
  /// actually transfers (ZCHF on Ethereum), filtered before it is read.
  final double? amount;

  const LnurlpTransferAssetDto({required this.asset, this.amount});

  factory LnurlpTransferAssetDto.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    final amount = rawAmount == null ? null : double.parse(rawAmount.toString());
    return LnurlpTransferAssetDto(
      asset: json['asset'] as String,
      amount: amount,
    );
  }
}
