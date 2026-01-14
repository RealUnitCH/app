import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/eip7702/eip7702_confirm_dto.dart';

class RealUnitSellConfirmDto {
  final Eip7702ConfirmDto eip7702ConfirmDto;

  const RealUnitSellConfirmDto({
    required this.eip7702ConfirmDto,
  });

  Map<String, dynamic> toJson() {
    return {
      'eip7702': eip7702ConfirmDto.toJson(),
    };
  }
}
