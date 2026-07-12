// We deliberately use non-const constructors throughout this file so the
// generative constructor lines get counted as executed in the coverage
// report. Const-only construction is a compile-time optimisation and is
// not visible to the line-coverage instrumentation.
// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/pin/bloc/auth/pin_auth_cubit.dart';

/// Equatable-`props` surface tests for `PinAuthState`.
void main() {
  group('PinAuthState defaults + ctor', () {
    test('defaults: both flags false', () {
      final state = PinAuthState();
      expect(state.isPinSetup, isFalse);
      expect(state.isPinVerified, isFalse);
      expect(state.props, [false, false]);
    });
  });

  group('PinAuthState equality', () {
    test('same flags is equal and props match', () {
      final a = PinAuthState(isPinSetup: true, isPinVerified: true);
      final b = PinAuthState(isPinSetup: true, isPinVerified: true);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.props, [true, true]);
    });

    test('different isPinSetup is unequal', () {
      final a = PinAuthState(isPinSetup: true);
      final b = PinAuthState(isPinSetup: false);
      expect(a, isNot(equals(b)));
    });

    test('different isPinVerified is unequal', () {
      final a = PinAuthState(isPinVerified: true);
      final b = PinAuthState(isPinVerified: false);
      expect(a, isNot(equals(b)));
    });
  });

  group('PinAuthState.copyWith', () {
    test('copyWith with isPinSetup flips only that flag', () {
      final base = PinAuthState();
      final next = base.copyWith(isPinSetup: true);
      expect(next.isPinSetup, isTrue);
      expect(next.isPinVerified, isFalse);
    });

    test('copyWith with isPinVerified flips only that flag', () {
      final base = PinAuthState(isPinSetup: true);
      final next = base.copyWith(isPinVerified: true);
      expect(next.isPinSetup, isTrue);
      expect(next.isPinVerified, isTrue);
    });

    test('copyWith with no arguments preserves both fields', () {
      final base = PinAuthState(isPinSetup: true, isPinVerified: true);
      final next = base.copyWith();
      expect(next, equals(base));
    });
  });
}
