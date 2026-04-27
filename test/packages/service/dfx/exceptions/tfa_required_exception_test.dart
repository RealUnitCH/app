import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/tfa_required_exception.dart';

void main() {
  group('$TfaRequiredException', () {
    test('always has statusCode 403', () {
      const exception = TfaRequiredException(
        code: 'TFA_REQUIRED',
        message: '2FA required',
      );

      expect(exception.statusCode, 403);
    });

    test('fromJson populates code, message, level and statusCode 403', () {
      final exception = TfaRequiredException.fromJson({
        'code': 'TFA_REQUIRED',
        'message': '2FA required (strict)',
        'level': 'strict',
      });

      expect(exception.code, 'TFA_REQUIRED');
      expect(exception.message, '2FA required (strict)');
      expect(exception.level, 'strict');
      expect(exception.statusCode, 403);
    });

    test('fromJson tolerates missing level', () {
      final exception = TfaRequiredException.fromJson({
        'code': 'TFA_REQUIRED',
        'message': '2FA required',
      });

      expect(exception.level, isNull);
      expect(exception.statusCode, 403);
    });
  });

  group('${ApiException}.fromJson', () {
    test('dispatches code: TFA_REQUIRED to $TfaRequiredException', () {
      final exception = ApiException.fromJson({
        'code': 'TFA_REQUIRED',
        'message': '2FA required (strict)',
        'level': 'strict',
      });

      expect(exception, isA<TfaRequiredException>());
      expect(exception.statusCode, 403);
    });
  });
}
