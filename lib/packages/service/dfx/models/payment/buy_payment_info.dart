import 'package:realunit_wallet/styles/currency.dart';

class BuyPaymentInfo {
  final String iban;
  final String bic;
  final String name;
  final String street;
  final String number;
  final String zip;
  final String city;
  final String country;
  final Currency currency;

  const BuyPaymentInfo({
    required this.iban,
    required this.bic,
    required this.name,
    required this.street,
    required this.number,
    required this.zip,
    required this.city,
    required this.country,
    required this.currency,
  });
}
