import 'package:realunit_wallet/packages/service/dfx/exceptions/realunit_api_exception.dart';

class RegistrationRequiredException extends ApiException {
  const RegistrationRequiredException({
    required super.code,
    required super.message,
  });

  factory RegistrationRequiredException.fromJson(Map<String, dynamic> json) {
    return RegistrationRequiredException(
      code: json['code'] as String,
      message: json['message'] as String,
    );
  }

  @override
  String toString() => 'RegistrationRequiredException: $message';
}

class KycLevelRequiredException extends ApiException {
  final int requiredLevel;
  final int currentLevel;

  const KycLevelRequiredException({
    required super.code,
    required super.message,
    required this.requiredLevel,
    required this.currentLevel,
  });

  factory KycLevelRequiredException.fromJson(Map<String, dynamic> json) {
    return KycLevelRequiredException(
      code: json['code'] as String,
      message: json['message'] as String,
      requiredLevel: json['requiredLevel'] as int,
      currentLevel: json['currentLevel'] as int,
    );
  }

  @override
  String toString() =>
      'KycLevelRequiredException: $message (required: $requiredLevel, current: $currentLevel)';
}
