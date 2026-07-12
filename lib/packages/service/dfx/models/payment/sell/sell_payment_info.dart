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
  final String depositAddress;
  final String tokenAddress;
  final int chainId;
  final double ethBalance;
  final double requiredGasEth;
  // Fields below come from the API quote response. The backend is the
  // authority on whether the quote is valid for trading and what the
  // current min/max limits are for the user+currency combination.
  final bool isValid;
  final double minVolume;
  final double maxVolume;
  final String? error;

  const SellPaymentInfo({
    required this.id,
    required this.eip7702,
    required this.amount,
    required this.exchangeRate,
    required this.rate,
    required this.beneficiary,
    required this.estimatedAmount,
    required this.currency,
    required this.depositAddress,
    required this.tokenAddress,
    required this.chainId,
    required this.ethBalance,
    required this.requiredGasEth,
    this.isValid = true,
    this.minVolume = 0,
    this.maxVolume = double.infinity,
    this.error,
  });
}
