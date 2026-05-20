import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';
import 'package:realunit_wallet/packages/wallet/exceptions/signing_cancelled_exception.dart';

// Guard against a recurring failure mode: an Exception subclass without a
// toString() override gets rendered as `Instance of '...'` whenever a cubit
// or service falls back to surfacing the raw error string. Every typed
// exception in this app must therefore expose a human-readable message.
//
// Add new typed exceptions to this list as they are introduced.
void main() {
  group('exception toString surface', () {
    final exceptions = <Object>[
      const BitboxNotConnectedException(),
      const SigningCancelledException(),
    ];

    for (final ex in exceptions) {
      test('${ex.runtimeType} renders a readable string', () {
        final rendered = ex.toString();
        expect(
          rendered,
          isNot(contains('Instance of')),
          reason:
              '${ex.runtimeType} is missing a toString() override and would '
              'surface as "Instance of ..." if it leaked to the UI.',
        );
        expect(rendered, isNotEmpty);
      });
    }
  });
}
