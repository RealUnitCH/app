import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_status.dart';

class RealUnitRegistrationResponseDto {
  final RegistrationStatus status;

  /// Company rejection sentence on `forwarding_failed`. Optional and absent
  /// on older servers; a missing key, JSON null, or a blank string is stored
  /// as null.
  final String? rejectionMessage;

  const RealUnitRegistrationResponseDto({
    required this.status,
    this.rejectionMessage,
  });

  factory RealUnitRegistrationResponseDto.fromJson(Map<String, dynamic> json) {
    return RealUnitRegistrationResponseDto(
      status: RegistrationStatus.fromString(json['status'] as String),
      rejectionMessage: _optionalRejectionMessage(json['rejectionMessage']),
    );
  }
}

/// Wire `rejectionMessage`: missing, JSON null, non-string, or blank → null.
String? _optionalRejectionMessage(Object? value) {
  if (value is! String) return null;
  if (value.trim().isEmpty) return null;
  return value;
}
