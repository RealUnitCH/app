// We deliberately use non-const constructors throughout this file so the
// generative constructor lines get counted as executed in the coverage
// report.
// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/support/cubits/support_email_capture/support_email_capture_cubit.dart';

void main() {
  group('$SupportEmailCaptureInitial / Loading / Success', () {
    test('Initial: equal across instances, empty props', () {
      final a = SupportEmailCaptureInitial();
      final b = SupportEmailCaptureInitial();
      expect(a, equals(b));
      expect(a.props, isEmpty);
    });

    test('Loading: equal across instances', () {
      final a = SupportEmailCaptureLoading();
      final b = SupportEmailCaptureLoading();
      expect(a, equals(b));
    });

    test('Success: equal across instances', () {
      final a = SupportEmailCaptureSuccess();
      final b = SupportEmailCaptureSuccess();
      expect(a, equals(b));
    });

    test('Initial vs Loading vs Success are distinct (runtimeType)', () {
      final i = SupportEmailCaptureInitial();
      final l = SupportEmailCaptureLoading();
      final s = SupportEmailCaptureSuccess();
      expect(i, isNot(equals(l)));
      expect(l, isNot(equals(s)));
      expect(i, isNot(equals(s)));
    });
  });

  group('$SupportEmailCaptureFailure', () {
    test('same error + same message is equal', () {
      final a = SupportEmailCaptureFailure(
        error: SupportEmailCaptureError.unknown,
        message: 'x',
      );
      final b = SupportEmailCaptureFailure(
        error: SupportEmailCaptureError.unknown,
        message: 'x',
      );
      expect(a, equals(b));
    });

    test('different error is unequal', () {
      final a = SupportEmailCaptureFailure(
        error: SupportEmailCaptureError.unknown,
        message: 'x',
      );
      final b = SupportEmailCaptureFailure(
        error: SupportEmailCaptureError.mergeRequested,
        message: 'x',
      );
      expect(a, isNot(equals(b)));
    });

    test('different message is unequal', () {
      final a = SupportEmailCaptureFailure(
        error: SupportEmailCaptureError.unknown,
        message: 'x',
      );
      final b = SupportEmailCaptureFailure(
        error: SupportEmailCaptureError.unknown,
        message: 'y',
      );
      expect(a, isNot(equals(b)));
    });
  });
}
