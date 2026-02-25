import 'package:realunit_wallet/packages/service/dfx/models/user/dto/real_unit_user_data_dto.dart';

class RealUnitWalletStatusDto {
  final bool isRegistered;
  final RealUnitUserDataDto? realUnitUserDataDto;

  RealUnitWalletStatusDto({
    required this.isRegistered,
    this.realUnitUserDataDto,
  });

  factory RealUnitWalletStatusDto.fromJson(Map<String, dynamic> json) {
    return RealUnitWalletStatusDto(
      isRegistered: json['isRegistered'] as bool,
      realUnitUserDataDto: json['userData'] != null
          ? RealUnitUserDataDto.fromJson(json['userData'] as Map<String, dynamic>)
          : null,
    );
  }
}
