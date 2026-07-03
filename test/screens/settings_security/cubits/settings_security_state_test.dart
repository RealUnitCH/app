import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/settings_security/cubits/settings_security_cubit.dart';

void main() {
  group('$SettingsSecurityState', () {
    test('defaults to all-false, no error', () {
      const state = SettingsSecurityState();
      expect(state.biometricSupported, isFalse);
      expect(state.biometricEnabled, isFalse);
      expect(state.isBusy, isFalse);
      expect(state.error, isNull);
      expect(state.props, [false, false, false, null]);
    });

    test('value equality via props', () {
      expect(
        const SettingsSecurityState(biometricSupported: true, biometricEnabled: true),
        const SettingsSecurityState(biometricSupported: true, biometricEnabled: true),
      );
      expect(
        const SettingsSecurityState(biometricEnabled: true),
        isNot(const SettingsSecurityState(biometricEnabled: false)),
      );
    });

    test('copyWith overrides only the provided fields', () {
      const base = SettingsSecurityState(biometricSupported: true);
      final busy = base.copyWith(isBusy: true);
      expect(busy.biometricSupported, isTrue);
      expect(busy.isBusy, isTrue);
      expect(busy.biometricEnabled, isFalse);

      final enabled = base.copyWith(biometricEnabled: true);
      expect(enabled.biometricEnabled, isTrue);
      expect(enabled.biometricSupported, isTrue);
    });

    test('error is transient: a copyWith that omits it clears the signal', () {
      const withError = SettingsSecurityState(
        biometricSupported: true,
        error: SettingsSecurityError.biometricEnableFailed,
      );
      expect(withError.error, SettingsSecurityError.biometricEnableFailed);

      final cleared = withError.copyWith(isBusy: true);
      expect(cleared.error, isNull);
      expect(cleared.biometricSupported, isTrue);
      expect(cleared.isBusy, isTrue);
    });
  });
}
