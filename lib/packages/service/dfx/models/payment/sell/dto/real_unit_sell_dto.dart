import 'package:realunit_wallet/styles/currency.dart';

class RealUnitSellDto {
  final int? amount;
  final int? targetAmount;
  final String iban;
  final Currency currency;

  RealUnitSellDto({
    this.amount,
    this.targetAmount,
    required this.iban,
    this.currency = Currency.chf,
  }) {
    assert(
      (amount != null && targetAmount == null) || (amount == null && targetAmount != null),
      'Either amount or targetAmount must be provided, but not both.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (amount != null) 'amount': amount,
      if (targetAmount != null) 'targetAmount': targetAmount,
      'iban': iban,
      'currency': currency.code,
    };
  }
}
