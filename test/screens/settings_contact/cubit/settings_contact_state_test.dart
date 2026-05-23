// We deliberately use non-const constructors throughout this file so the
// generative constructor lines get counted as executed in the coverage
// report. Const-only construction is a compile-time optimisation and is
// not visible to the line-coverage instrumentation.
// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/settings_contact/cubit/settings_contact_cubit.dart';

/// Equatable-`props` surface tests for `SettingsContactState`.
void main() {
  group('SettingsContactState base', () {
    test('base instance has empty props', () {
      final base = SettingsContactState();
      expect(base.props, isEmpty);
    });
  });

  group('SettingsContactInitial', () {
    test('two instances are equal and props are empty', () {
      final a = SettingsContactInitial();
      final b = SettingsContactInitial();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.props, isEmpty);
    });
  });

  group('SettingsContactLoading', () {
    test('two instances are equal and props are empty', () {
      final a = SettingsContactLoading();
      final b = SettingsContactLoading();
      expect(a, equals(b));
      expect(a.props, isEmpty);
    });
  });

  group('SettingsContactSuccess', () {
    test('default supportAvailable is false', () {
      final a = SettingsContactSuccess();
      expect(a.supportAvailable, isFalse);
      expect(a.props, [false]);
    });

    test('same supportAvailable is equal and props match', () {
      final a = SettingsContactSuccess(supportAvailable: true);
      final b = SettingsContactSuccess(supportAvailable: true);
      expect(a, equals(b));
      expect(a.props, [true]);
    });

    test('different supportAvailable is unequal', () {
      final a = SettingsContactSuccess(supportAvailable: true);
      final b = SettingsContactSuccess();
      expect(a, isNot(equals(b)));
    });

    test('copyWith with new value flips the flag', () {
      final base = SettingsContactSuccess();
      final next = base.copyWith(supportAvailable: true);
      expect(next.supportAvailable, isTrue);
    });

    test('copyWith without args preserves the flag', () {
      final base = SettingsContactSuccess(supportAvailable: true);
      final next = base.copyWith();
      expect(next.supportAvailable, isTrue);
    });
  });

  group('SettingsContactFailure', () {
    test('same message is equal and props match', () {
      final a = SettingsContactFailure(message: 'boom');
      final b = SettingsContactFailure(message: 'boom');
      expect(a, equals(b));
      expect(a.props, ['boom']);
    });

    test('different messages are unequal', () {
      final a = SettingsContactFailure(message: 'boom');
      final b = SettingsContactFailure(message: 'other');
      expect(a, isNot(equals(b)));
    });
  });

  group('SettingsContactState (cross-subclass identity)', () {
    test('Initial vs Loading are unequal even though props match', () {
      expect(SettingsContactInitial(), isNot(equals(SettingsContactLoading())));
    });

    test('Success(false) vs Failure are unequal', () {
      final s = SettingsContactSuccess();
      final f = SettingsContactFailure(message: 'boom');
      expect(s, isNot(equals(f)));
    });
  });
}
