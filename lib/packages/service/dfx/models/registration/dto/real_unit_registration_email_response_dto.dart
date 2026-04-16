import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_email_status.dart';

class RealUnitRegistrationEmailResponseDto {
  final RegistrationEmailStatus status;

  const RealUnitRegistrationEmailResponseDto({
    required this.status,
  });

  factory RealUnitRegistrationEmailResponseDto.fromJson(Map<String, dynamic> json) {
    return RealUnitRegistrationEmailResponseDto(
      status: RegistrationEmailStatus.fromString(json['status'] as String),
    );
  }
}
