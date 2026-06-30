import 'package:realunit_wallet/styles/currency.dart';
import 'package:realunit_wallet/styles/language.dart';

class SingleReceiptDto {
  final String txId;
  final Currency currency;
  final Language language;

  const SingleReceiptDto({
    required this.txId,
    this.currency = Currency.chf,
    this.language = Language.en,
  });

  Map<String, dynamic> toJson() {
    return {
      'txHash': txId,
      'currency': currency.code,
      'language': language.code.toUpperCase(),
    };
  }
}
