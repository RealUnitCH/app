// We deliberately use non-const constructors throughout this file so the
// generative constructor lines get counted as executed in the coverage
// report. Const-only construction is a compile-time optimisation and is
// not visible to the line-coverage instrumentation.
// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/pin/bloc/verify_pin/verify_pin_cubit.dart';

/// Equatable-`props` surface tests for `VerifyPinState` and its subclasses.
void main() {
  group('VerifyPinState (base)', () {
    test('defaults: empty pin, 0 failed attempts', () {
      final state = VerifyPinState();
      expect(state.pin, '');
      expect(state.failedAttempts, 0);
      expect(state.props, ['', 0]);
    });

    test('same pin + same attempts is equal', () {
      final a = VerifyPinState(pin: '1234', failedAttempts: 1);
      final b = VerifyPinState(pin: '1234', failedAttempts: 1);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different pin is unequal', () {
      final a = VerifyPinState(pin: '1234');
      final b = VerifyPinState(pin: '0000');
      expect(a, isNot(equals(b)));
    });

    test('different failedAttempts is unequal', () {
      final a = VerifyPinState(pin: '1234', failedAttempts: 1);
      final b = VerifyPinState(pin: '1234', failedAttempts: 2);
      expect(a, isNot(equals(b)));
    });

    test('copyWith preserves untouched fields', () {
      final base = VerifyPinState(pin: '1234');
      final next = base.copyWith(failedAttempts: 3);
      expect(next.pin, '1234');
      expect(next.failedAttempts, 3);
    });

    test('copyWith with no arguments preserves all fields', () {
      final base = VerifyPinState(pin: '1234', failedAttempts: 3);
      final next = base.copyWith();
      expect(next, equals(base));
    });
  });

  group('VerifyPinSuccess', () {
    test('two instances are equal with empty pin', () {
      final a = VerifyPinSuccess();
      final b = VerifyPinSuccess();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.pin, '');
      expect(a.failedAttempts, 0);
    });
  });

  group('VerifyPinVerifying', () {
    test('carries the entered pin and is equal for same pin + attempts', () {
      final a = VerifyPinVerifying(pin: '123456');
      final b = VerifyPinVerifying(pin: '123456');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.pin, '123456');
      expect(a.failedAttempts, 0);
    });

    test('different pin is unequal', () {
      final a = VerifyPinVerifying(pin: '123456');
      final b = VerifyPinVerifying(pin: '654321');
      expect(a, isNot(equals(b)));
    });

    test('preserves failedAttempts', () {
      final a = VerifyPinVerifying(pin: '123456', failedAttempts: 3);
      expect(a.failedAttempts, 3);
    });
  });

  group('VerifyPinFailure', () {
    test('same failedAttempts is equal', () {
      final a = VerifyPinFailure(failedAttempts: 2);
      final b = VerifyPinFailure(failedAttempts: 2);
      expect(a, equals(b));
      expect(a.pin, '');
    });

    test('different failedAttempts is unequal', () {
      final a = VerifyPinFailure(failedAttempts: 1);
      final b = VerifyPinFailure(failedAttempts: 2);
      expect(a, isNot(equals(b)));
    });
  });

  group('VerifyPinTemporarilyLocked', () {
    test('same failedAttempts + same lockedUntil is equal', () {
      final t = DateTime.utc(2026, 5, 23, 12, 0, 0);
      final a = VerifyPinTemporarilyLocked(failedAttempts: 5, lockedUntil: t);
      final b = VerifyPinTemporarilyLocked(failedAttempts: 5, lockedUntil: t);
      expect(a, equals(b));
      // The override extends super.props with lockedUntil, so we explicitly
      // pin the order so any future refactor of `props` is caught.
      expect(a.props, ['', 5, t]);
    });

    test('different lockedUntil is unequal', () {
      final t1 = DateTime.utc(2026, 5, 23, 12);
      final t2 = DateTime.utc(2026, 5, 23, 13);
      final a = VerifyPinTemporarilyLocked(failedAttempts: 5, lockedUntil: t1);
      final b = VerifyPinTemporarilyLocked(failedAttempts: 5, lockedUntil: t2);
      expect(a, isNot(equals(b)));
    });
  });

  group('VerifyPinLocked', () {
    test('same failedAttempts is equal', () {
      final a = VerifyPinLocked(failedAttempts: 99);
      final b = VerifyPinLocked(failedAttempts: 99);
      expect(a, equals(b));
      expect(a.pin, '');
    });

    test('different failedAttempts is unequal', () {
      final a = VerifyPinLocked(failedAttempts: 99);
      final b = VerifyPinLocked(failedAttempts: 100);
      expect(a, isNot(equals(b)));
    });
  });

  group('VerifyPinState (cross-subclass identity)', () {
    test('Success vs Failure with identical props are unequal', () {
      // Success.pin='' & failedAttempts=0 mirrors Failure(failedAttempts:0).
      // Equatable's runtimeType check distinguishes them.
      final s = VerifyPinSuccess();
      final f = VerifyPinFailure(failedAttempts: 0);
      expect(s, isNot(equals(f)));
    });

    test('Failure vs Locked with same failedAttempts are unequal', () {
      final f = VerifyPinFailure(failedAttempts: 3);
      final l = VerifyPinLocked(failedAttempts: 3);
      expect(f, isNot(equals(l)));
    });
  });
}
