import 'package:realunit_wallet/generated/i18n.dart';

class OpenCryptoPayException implements Exception {
  final String message;

  OpenCryptoPayException([this.message = '']);

  @override
  String toString() => 'OpenCryptoPayException${message.isNotEmpty ? ': $message' : ''}';
}

class OpenCryptoPayNotSupportedException extends OpenCryptoPayException {
  final String provider;

  OpenCryptoPayNotSupportedException(this.provider);

  @override
  String get message => S.current.openCryptoPayNotSupported(provider);
}
