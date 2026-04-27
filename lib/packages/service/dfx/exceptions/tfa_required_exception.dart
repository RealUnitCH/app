import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';

class TfaRequiredException extends ApiException {
  final String? level;

  const TfaRequiredException({
    required super.code,
    required super.message,
    this.level,
  }) : super(statusCode: 403);

  factory TfaRequiredException.fromJson(Map<String, dynamic> json) {
    return TfaRequiredException(
      code: json['code'] as String,
      message: json['message'] as String,
      level: json['level'] as String?,
    );
  }

  @override
  String toString() => 'TfaRequiredException: $message${level != null ? ' (level: $level)' : ''}';
}
