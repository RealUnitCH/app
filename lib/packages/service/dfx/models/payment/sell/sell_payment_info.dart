import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/eip7702/eip7702_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/real_unit_sell_payment_info_dto.dart';
import 'package:realunit_wallet/styles/currency.dart';

class SellPaymentInfo {
  final int id;
  final Eip7702Data eip7702;
  final int amount;
  final double exchangeRate;
  final double rate;
  final BeneficiaryDto beneficiary;
  final double estimatedAmount;
  final Currency currency;

  const SellPaymentInfo({
    required this.id,
    required this.eip7702,
    required this.amount,
    required this.exchangeRate,
    required this.rate,
    required this.beneficiary,
    required this.estimatedAmount,
    required this.currency,
  });
}
