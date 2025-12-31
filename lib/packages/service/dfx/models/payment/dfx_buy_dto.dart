import 'package:realunit_wallet/styles/currency.dart';

class DfxBuyDto {
  final num amount;
  final Currency currency;

  const DfxBuyDto({
    required this.amount,
    this.currency = Currency.chf,
  });

  factory DfxBuyDto.fromJson(Map<String, dynamic> json) {
    return DfxBuyDto(
      amount: (json['amount'] as num),
      currency:
          json['currency'] != null ? Currency.fromCode(json['currency'] as String) : Currency.chf,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency.code,
    };
  }
}
