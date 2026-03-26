import 'package:equatable/equatable.dart';
import 'package:realunit_wallet/styles/currency.dart';

class BuyPaymentInfo extends Equatable {
  final int id;
  final String iban;
  final String bic;
  final String name;
  final String street;
  final String number;
  final String zip;
  final String city;
  final String country;
  final Currency currency;
  final String? paymentRequest;
  final String? remittanceInfo;

  const BuyPaymentInfo({
    required this.id,
    required this.iban,
    required this.bic,
    required this.name,
    required this.street,
    required this.number,
    required this.zip,
    required this.city,
    required this.country,
    required this.currency,
    this.paymentRequest,
    this.remittanceInfo,
  });

  @override
  List<Object?> get props => [id, iban, bic, name, street, number, zip, city, country, currency, paymentRequest, remittanceInfo];
}
