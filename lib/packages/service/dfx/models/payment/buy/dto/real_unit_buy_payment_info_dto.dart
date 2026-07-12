import 'package:realunit_wallet/packages/service/dfx/models/fees/dfx_fees_data.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/price_step_dto.dart';
import 'package:realunit_wallet/styles/currency.dart';

class RealUnitBuyPaymentInfoDto {
  final int id;
  final int routeId;
  final DateTime timestamp;
  final String iban;
  final String bic;
  final String name;
  final String street;
  final String number;
  final String zip;
  final String city;
  final String country;
  final double amount;
  final Currency currency;
  final DfxFeesData fees;
  final double? minVolume;
  final double? maxVolume;
  final double minVolumeTarget;
  final double maxVolumeTarget;
  final double exchangeRate;
  final double rate;
  final List<PriceStep> priceSteps;
  final double estimatedAmount;
  final String? paymentRequest;
  final String? remittanceInfo;
  final bool isValid;
  final String? error;

  const RealUnitBuyPaymentInfoDto({
    required this.id,
    required this.routeId,
    required this.timestamp,
    required this.iban,
    required this.bic,
    required this.name,
    required this.street,
    required this.number,
    required this.zip,
    required this.city,
    required this.country,
    required this.amount,
    required this.currency,
    required this.fees,
    this.minVolume,
    this.maxVolume,
    required this.minVolumeTarget,
    required this.maxVolumeTarget,
    required this.exchangeRate,
    required this.rate,
    required this.priceSteps,
    required this.estimatedAmount,
    this.paymentRequest,
    this.remittanceInfo,
    required this.isValid,
    this.error,
  });

  factory RealUnitBuyPaymentInfoDto.fromJson(Map<String, dynamic> json) {
    return RealUnitBuyPaymentInfoDto(
      id: json['id'] as int,
      routeId: json['routeId'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      iban: json['iban'] as String,
      bic: json['bic'] as String,
      name: json['name'] as String,
      street: json['street'] as String,
      number: json['number'] as String,
      zip: json['zip'] as String,
      city: json['city'] as String,
      country: json['country'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: Currency.fromCode(json['currency'] as String),
      fees: DfxFeesData.fromJson(json['fees'] as Map<String, dynamic>),
      minVolume: (json['minVolume'] as num?)?.toDouble(),
      maxVolume: (json['maxVolume'] as num?)?.toDouble(),
      minVolumeTarget: (json['minVolumeTarget'] as num).toDouble(),
      maxVolumeTarget: (json['maxVolumeTarget'] as num).toDouble(),
      exchangeRate: (json['exchangeRate'] as num).toDouble(),
      rate: (json['rate'] as num).toDouble(),
      priceSteps: (json['priceSteps'] as List<dynamic>)
          .map((e) => PriceStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      estimatedAmount: (json['estimatedAmount'] as num).toDouble(),
      paymentRequest: json['paymentRequest'] as String?,
      remittanceInfo: json['remittanceInfo'] as String?,
      isValid: json['isValid'] as bool,
      error: json['error'] as String?,
    );
  }
}
