import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_status.dart';

class RealUnitRegistrationResponseDto {
  final RegistrationStatus status;

  const RealUnitRegistrationResponseDto({
    required this.status,
  });

  factory RealUnitRegistrationResponseDto.fromJson(Map<String, dynamic> json) {
    return RealUnitRegistrationResponseDto(
      status: RegistrationStatus.fromString(json['status'] as String),
    );
  }
}
