import 'package:realunit_wallet/styles/currency.dart';
import 'package:realunit_wallet/styles/language.dart';

class MultiReceiptDto {
  final List<String> txIds;
  final List<String> eventIds;
  final Currency currency;
  final Language language;

  const MultiReceiptDto({
    required this.txIds,
    this.eventIds = const [],
    this.currency = Currency.chf,
    this.language = Language.en,
  });

  Map<String, dynamic> toJson() {
    return {
      'txHashes': txIds,
      if (eventIds.isNotEmpty) 'eventIds': eventIds,
      'currency': currency.code,
      'language': language.code.toUpperCase(),
    };
  }
}
