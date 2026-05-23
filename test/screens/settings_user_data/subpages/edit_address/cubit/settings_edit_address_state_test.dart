import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/edit_address/cubit/settings_edit_address_cubit.dart';

/// Equatable-`props` surface tests for `SettingsEditAddressState`.
///
/// The existing cubit test under `subpages/settings_edit_address_cubit_test.dart`
/// exercises *some* transitions, but never hits the value-type identity of
/// `SettingsEditAddressInitial`, `Pending`, `Success`, nor the props of
/// `Ready`, `Submitting`, `Failure`. These tests close the gap.
void main() {
  group('SettingsEditAddressInitial', () {
    test('two instances are equal and share hashCode', () {
      const a = SettingsEditAddressInitial();
      const b = SettingsEditAddressInitial();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.props, isEmpty);
    });
  });

  group('SettingsEditAddressLoading', () {
    test('two instances are equal', () {
      const a = SettingsEditAddressLoading();
      const b = SettingsEditAddressLoading();
      expect(a, equals(b));
      expect(a.props, isEmpty);
    });
  });

  group('SettingsEditAddressReady', () {
    test('same url is equal and props match', () {
      const a = SettingsEditAddressReady('https://kyc.example/start');
      const b = SettingsEditAddressReady('https://kyc.example/start');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.props, ['https://kyc.example/start']);
    });

    test('different urls are unequal', () {
      const a = SettingsEditAddressReady('https://kyc.example/a');
      const b = SettingsEditAddressReady('https://kyc.example/b');
      expect(a, isNot(equals(b)));
    });
  });

  group('SettingsEditAddressPending', () {
    test('two instances are equal', () {
      const a = SettingsEditAddressPending();
      const b = SettingsEditAddressPending();
      expect(a, equals(b));
      expect(a.props, isEmpty);
    });
  });

  group('SettingsEditAddressSubmitting', () {
    test('same url is equal and props match', () {
      const a = SettingsEditAddressSubmitting('https://kyc.example/submit');
      const b = SettingsEditAddressSubmitting('https://kyc.example/submit');
      expect(a, equals(b));
      expect(a.props, ['https://kyc.example/submit']);
    });

    test('different urls are unequal', () {
      const a = SettingsEditAddressSubmitting('https://kyc.example/a');
      const b = SettingsEditAddressSubmitting('https://kyc.example/b');
      expect(a, isNot(equals(b)));
    });
  });

  group('SettingsEditAddressSuccess', () {
    test('two instances are equal', () {
      const a = SettingsEditAddressSuccess();
      const b = SettingsEditAddressSuccess();
      expect(a, equals(b));
      expect(a.props, isEmpty);
    });
  });

  group('SettingsEditAddressFailure', () {
    test('same message is equal and props match', () {
      const a = SettingsEditAddressFailure('rejected');
      const b = SettingsEditAddressFailure('rejected');
      expect(a, equals(b));
      expect(a.props, ['rejected']);
    });

    test('different messages are unequal', () {
      const a = SettingsEditAddressFailure('rejected');
      const b = SettingsEditAddressFailure('timeout');
      expect(a, isNot(equals(b)));
    });
  });

  group('SettingsEditAddressState (cross-subclass identity)', () {
    test('different empty subclasses are not equal even though props match', () {
      // Initial, Loading, Pending, Success all inherit `props => []`.
      // Equatable's runtimeType check makes them distinguishable.
      expect(
        const SettingsEditAddressInitial(),
        isNot(equals(const SettingsEditAddressLoading())),
      );
      expect(
        const SettingsEditAddressLoading(),
        isNot(equals(const SettingsEditAddressPending())),
      );
      expect(
        const SettingsEditAddressPending(),
        isNot(equals(const SettingsEditAddressSuccess())),
      );
    });

    test('Ready and Submitting with same url are still distinct', () {
      // Same payload but distinct types — must compare unequal.
      const ready = SettingsEditAddressReady('https://kyc.example/x');
      const submitting = SettingsEditAddressSubmitting('https://kyc.example/x');
      expect(ready, isNot(equals(submitting)));
    });
  });
}
