import 'package:realunit_wallet/styles/currency.dart';
import 'package:realunit_wallet/styles/language.dart';

class MultiReceiptDto {
  final List<String> txIds;
  final Currency currency;
  final Language? language;

  const MultiReceiptDto({
    required this.txIds,
    this.currency = Currency.chf,
    this.language,
  });

  Map<String, dynamic> toJson() {
    return {
      'txHashes': txIds,
      'currency': currency.code,
      if (language != null) 'language': language!.code.toUpperCase(),
    };
  }
}
