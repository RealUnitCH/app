import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/real_unit_sell_step.dart';

class BroadcastTransactionRequestDto {
  final RealUnitSellStep step;
  final String signedTransaction;

  const BroadcastTransactionRequestDto({
    required this.step,
    required this.signedTransaction,
  });

  Map<String, dynamic> toJson() {
    return {
      'step': step.name,
      'signedTransaction': signedTransaction,
    };
  }
}
