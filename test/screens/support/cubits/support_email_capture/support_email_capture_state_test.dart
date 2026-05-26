// We deliberately use non-const constructors throughout this file so the
// generative constructor lines get counted as executed in the coverage
// report. Const-only construction is a compile-time optimisation and is
// not visible to the line-coverage instrumentation.
// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/support/cubits/support_email_capture/support_email_capture_cubit.dart';

/// Equatable-`props` surface tests for `SupportEmailCaptureState`.
void main() {
  group('SupportEmailCaptureInitial', () {
    test('two instances are equal and props are empty', () {
      final a = SupportEmailCaptureInitial();
      final b = SupportEmailCaptureInitial();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.props, isEmpty);
    });
  });

  group('SupportEmailCaptureSubmitting', () {
    test('two instances are equal and props are empty', () {
      final a = SupportEmailCaptureSubmitting();
      final b = SupportEmailCaptureSubmitting();
      expect(a, equals(b));
      expect(a.props, isEmpty);
    });
  });

  group('SupportEmailCaptureSuccess', () {
    test('two instances are equal and props are empty', () {
      final a = SupportEmailCaptureSuccess();
      final b = SupportEmailCaptureSuccess();
      expect(a, equals(b));
      expect(a.props, isEmpty);
    });
  });

  group('SupportEmailCaptureFailure', () {
    test('same message is equal and props match', () {
      final a = SupportEmailCaptureFailure(message: 'boom');
      final b = SupportEmailCaptureFailure(message: 'boom');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.props, ['boom']);
    });

    test('different messages are unequal', () {
      final a = SupportEmailCaptureFailure(message: 'boom');
      final b = SupportEmailCaptureFailure(message: 'other');
      expect(a, isNot(equals(b)));
    });
  });

  group('SupportEmailCaptureState (cross-subclass identity)', () {
    test('Initial vs Submitting are unequal even though props match', () {
      expect(
        SupportEmailCaptureInitial(),
        isNot(equals(SupportEmailCaptureSubmitting())),
      );
    });

    test('Submitting vs Success are unequal', () {
      expect(
        SupportEmailCaptureSubmitting(),
        isNot(equals(SupportEmailCaptureSuccess())),
      );
    });

    test('Success vs Failure are unequal', () {
      expect(
        SupportEmailCaptureSuccess(),
        isNot(equals(SupportEmailCaptureFailure(message: 'x'))),
      );
    });
  });
}
