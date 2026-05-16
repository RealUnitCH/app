import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';
import 'package:realunit_wallet/packages/wallet/exceptions/signing_cancelled_exception.dart';

void main() {
  group('$SigningCancelledException', () {
    test('is an Exception', () {
      expect(const SigningCancelledException(), isA<Exception>());
    });

    test('toString returns "SigningCancelledException"', () {
      expect(const SigningCancelledException().toString(), 'SigningCancelledException');
    });

    test('const constructor produces the same identity', () {
      // Pinned because callers compare by identity / type, not deep equality.
      const a = SigningCancelledException();
      const b = SigningCancelledException();
      expect(identical(a, b), isTrue);
    });
  });

  group('$BitboxNotConnectedException', () {
    test('is an Exception', () {
      expect(const BitboxNotConnectedException(), isA<Exception>());
    });

    test('const constructor produces the same identity', () {
      const a = BitboxNotConnectedException();
      const b = BitboxNotConnectedException();
      expect(identical(a, b), isTrue);
    });
  });
}
