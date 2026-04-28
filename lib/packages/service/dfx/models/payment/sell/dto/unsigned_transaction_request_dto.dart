import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/real_unit_sell_step.dart';

class UnsignedTransactionRequestDto {
  final RealUnitSellStep step;
  final double? amount;

  const UnsignedTransactionRequestDto({
    required this.step,
    this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      'step': step.name,
      if (amount != null) 'amount': amount,
    };
  }
}
