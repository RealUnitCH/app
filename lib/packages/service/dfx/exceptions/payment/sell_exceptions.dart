import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';

class AlreadyConfirmedException extends ApiException {
  const AlreadyConfirmedException({
    super.statusCode,
    required super.code,
    required super.message,
  });

  @override
  String toString() => 'AlreadyConfirmedException: $message';
}
