import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/edit_name/cubit/settings_edit_name_cubit.dart';

/// Equatable-`props` surface tests for `SettingsEditNameState`.
///
/// Mirrors `SettingsEditAddressState` — both files declare the same Initial /
/// Loading / Ready / Pending / Submitting / Success / Failure shape and need
/// the same value-type identity coverage.
void main() {
  group('SettingsEditNameInitial', () {
    test('two instances are equal and share hashCode', () {
      const a = SettingsEditNameInitial();
      const b = SettingsEditNameInitial();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.props, isEmpty);
    });
  });

  group('SettingsEditNameLoading', () {
    test('two instances are equal', () {
      const a = SettingsEditNameLoading();
      const b = SettingsEditNameLoading();
      expect(a, equals(b));
      expect(a.props, isEmpty);
    });
  });

  group('SettingsEditNameReady', () {
    test('same url is equal and props match', () {
      const a = SettingsEditNameReady('https://kyc.example/name-start');
      const b = SettingsEditNameReady('https://kyc.example/name-start');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.props, ['https://kyc.example/name-start']);
    });

    test('different urls are unequal', () {
      const a = SettingsEditNameReady('https://kyc.example/a');
      const b = SettingsEditNameReady('https://kyc.example/b');
      expect(a, isNot(equals(b)));
    });
  });

  group('SettingsEditNamePending', () {
    test('two instances are equal', () {
      const a = SettingsEditNamePending();
      const b = SettingsEditNamePending();
      expect(a, equals(b));
      expect(a.props, isEmpty);
    });
  });

  group('SettingsEditNameSubmitting', () {
    test('same url is equal and props match', () {
      const a = SettingsEditNameSubmitting('https://kyc.example/name-submit');
      const b = SettingsEditNameSubmitting('https://kyc.example/name-submit');
      expect(a, equals(b));
      expect(a.props, ['https://kyc.example/name-submit']);
    });

    test('different urls are unequal', () {
      const a = SettingsEditNameSubmitting('https://kyc.example/a');
      const b = SettingsEditNameSubmitting('https://kyc.example/b');
      expect(a, isNot(equals(b)));
    });
  });

  group('SettingsEditNameSuccess', () {
    test('two instances are equal', () {
      const a = SettingsEditNameSuccess();
      const b = SettingsEditNameSuccess();
      expect(a, equals(b));
      expect(a.props, isEmpty);
    });
  });

  group('SettingsEditNameFailure', () {
    test('same message is equal and props match', () {
      const a = SettingsEditNameFailure('rejected');
      const b = SettingsEditNameFailure('rejected');
      expect(a, equals(b));
      expect(a.props, ['rejected']);
    });

    test('different messages are unequal', () {
      const a = SettingsEditNameFailure('rejected');
      const b = SettingsEditNameFailure('timeout');
      expect(a, isNot(equals(b)));
    });
  });

  group('SettingsEditNameState (cross-subclass identity)', () {
    test('different empty subclasses are not equal even though props match', () {
      expect(
        const SettingsEditNameInitial(),
        isNot(equals(const SettingsEditNameLoading())),
      );
      expect(
        const SettingsEditNameLoading(),
        isNot(equals(const SettingsEditNamePending())),
      );
      expect(
        const SettingsEditNamePending(),
        isNot(equals(const SettingsEditNameSuccess())),
      );
    });

    test('Ready and Submitting with same url are still distinct', () {
      const ready = SettingsEditNameReady('https://kyc.example/x');
      const submitting = SettingsEditNameSubmitting('https://kyc.example/x');
      expect(ready, isNot(equals(submitting)));
    });
  });
}
