import 'package:realunit_wallet/packages/service/dfx/exceptions/payment/buy_exceptions.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String? error;
  final String code;
  final String message;

  const ApiException({
    this.statusCode,
    this.error,
    required this.code,
    required this.message,
  });

  factory ApiException.fromJson(Map<String, dynamic> json) {
    final code = json['code'] as String?;

    switch (code) {
      case 'KYC_LEVEL_REQUIRED':
        return KycLevelRequiredException.fromJson(json);
      case 'REGISTRATION_REQUIRED':
        return RegistrationRequiredException.fromJson(json);
      default:
        return ApiException(
          code: code ?? 'UNKNOWN',
          message: json['message'] as String,
        );
    }
  }

  @override
  String toString() => 'RealUnitApiException: $message (code: $code)';
}
