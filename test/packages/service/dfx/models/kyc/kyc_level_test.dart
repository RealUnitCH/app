import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';

void main() {
  group('$KycLevel', () {
    test('values has exactly 8 entries', () {
      // 6 numeric levels + terminated + rejected. Catches accidental
      // additions to the enum that would silently bypass every
      // switch-on-level call site.
      expect(KycLevel.values, hasLength(8));
    });

    group('value (extension getter)', () {
      test('level0..level50 map to 0/10/20/30/40/50', () {
        expect(KycLevel.level0.value, 0);
        expect(KycLevel.level10.value, 10);
        expect(KycLevel.level20.value, 20);
        expect(KycLevel.level30.value, 30);
        expect(KycLevel.level40.value, 40);
        expect(KycLevel.level50.value, 50);
      });

      test('terminated → -10, rejected → -20', () {
        // Negative sentinels for terminal states. Pinned because the
        // server distinguishes between user-aborted and rejected KYC.
        expect(KycLevel.terminated.value, -10);
        expect(KycLevel.rejected.value, -20);
      });
    });

    group('fromValue (static)', () {
      test('round-trips every enum value', () {
        for (final level in KycLevel.values) {
          expect(KycLevelExtension.fromValue(level.value), level);
        }
      });

      test('throws ArgumentError on unknown numeric input', () {
        expect(() => KycLevelExtension.fromValue(99), throwsArgumentError);
        expect(() => KycLevelExtension.fromValue(-1), throwsArgumentError);
      });
    });
  });
}
