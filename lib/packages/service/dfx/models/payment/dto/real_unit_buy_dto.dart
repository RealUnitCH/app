import 'package:realunit_wallet/styles/currency.dart';

class RealUnitBuyDto {
  final num amount;
  final Currency currency;

  const RealUnitBuyDto({
    required this.amount,
    this.currency = Currency.chf,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency.code,
    };
  }
}
