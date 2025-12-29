import 'package:realunit_wallet/packages/service/dfx/models/registration/dfx_registration_status.dart';

class DfxRegistrationResponseDto {
  final DfxRegistrationStatus status;

  DfxRegistrationResponseDto({
    required this.status,
  });

  factory DfxRegistrationResponseDto.fromJson(Map<String, dynamic> json) {
    return DfxRegistrationResponseDto(
      status: DfxRegistrationStatus.fromString(json['status'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status.name,
      };
}
