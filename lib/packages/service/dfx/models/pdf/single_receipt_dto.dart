import 'package:realunit_wallet/styles/currency.dart';
import 'package:realunit_wallet/styles/language.dart';

class SingleReceiptDto {
  final String txId;
  final String? eventId;
  final Currency currency;
  final Language language;

  const SingleReceiptDto({
    required this.txId,
    this.eventId,
    this.currency = Currency.chf,
    this.language = Language.en,
  });

  Map<String, dynamic> toJson() {
    return {
      'txHash': txId,
      if (eventId != null) 'eventId': eventId,
      'currency': currency.code,
      'language': language.code.toUpperCase(),
    };
  }
}
