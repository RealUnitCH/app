import 'package:realunit_wallet/styles/currency.dart';

class SingleReceiptDto {
  final String txId;
  final Currency currency;

  const SingleReceiptDto({
    required this.txId,
    this.currency = Currency.chf,
  });

  Map<String, dynamic> toJson() {
    return {
      'txHash': txId,
      'currency': currency.code,
    };
  }
}
