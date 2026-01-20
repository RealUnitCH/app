import 'package:realunit_wallet/styles/currency.dart';
import 'package:realunit_wallet/styles/language.dart';

class BalancePdfDto {
  final String address;
  final Currency currency;
  final DateTime date;
  final Language language;

  const BalancePdfDto({
    required this.address,
    required this.currency,
    required this.date,
    this.language = Language.en,
  });

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'currency': currency.code,
      'date': date.toIso8601String(),
      'language': language.code.toUpperCase(),
    };
  }
}
