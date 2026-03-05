import 'package:realunit_wallet/styles/currency.dart';

class MultiReceiptDto {
  final List<String> txIds;
  final Currency currency;

  const MultiReceiptDto({
    required this.txIds,
    this.currency = Currency.chf,
  });

  Map<String, dynamic> toJson() {
    return {
      'txHashes': txIds,
      'currency': currency.code,
    };
  }
}
