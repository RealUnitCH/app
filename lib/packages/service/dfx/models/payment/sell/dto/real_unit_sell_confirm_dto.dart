import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/eip7702/eip7702_confirm_dto.dart';

class RealUnitSellConfirmDto {
  final Eip7702ConfirmDto? eip7702ConfirmDto;
  final String? txHash;

  const RealUnitSellConfirmDto({
    this.eip7702ConfirmDto,
    this.txHash,
  });

  Map<String, dynamic> toJson() {
    return {
      if (eip7702ConfirmDto != null) 'eip7702': eip7702ConfirmDto!.toJson(),
      if (txHash != null) 'txHash': txHash,
    };
  }
}
