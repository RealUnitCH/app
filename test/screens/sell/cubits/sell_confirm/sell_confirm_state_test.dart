// We deliberately use non-const constructors throughout this file so the
// generative constructor lines get counted as executed in the coverage
// report. Const-only construction is a compile-time optimisation and is
// not visible to the line-coverage instrumentation.
// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/sell/cubits/sell_confirm/sell_confirm_cubit.dart';

/// Equatable-`props` surface tests for `SellConfirmState`.
void main() {
  group('SellConfirmInitial', () {
    test('two instances are equal and props are empty', () {
      final a = SellConfirmInitial();
      final b = SellConfirmInitial();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.props, isEmpty);
    });
  });

  group('SellConfirmLoading', () {
    test('two instances are equal and props are empty', () {
      final a = SellConfirmLoading();
      final b = SellConfirmLoading();
      expect(a, equals(b));
      expect(a.props, isEmpty);
    });
  });

  group('SellConfirmSuccess', () {
    test('two instances are equal and props are empty', () {
      final a = SellConfirmSuccess();
      final b = SellConfirmSuccess();
      expect(a, equals(b));
      expect(a.props, isEmpty);
    });
  });

  group('SellConfirmFailure', () {
    test('same error is equal and props match', () {
      final a = SellConfirmFailure('boom');
      final b = SellConfirmFailure('boom');
      expect(a, equals(b));
      expect(a.props, ['boom']);
    });

    test('different errors are unequal', () {
      final a = SellConfirmFailure('boom');
      final b = SellConfirmFailure('other');
      expect(a, isNot(equals(b)));
    });
  });

  group('SellConfirmState (cross-subclass identity)', () {
    test('different payload-less subclasses are unequal', () {
      expect(SellConfirmInitial(), isNot(equals(SellConfirmLoading())));
      expect(SellConfirmLoading(), isNot(equals(SellConfirmSuccess())));
    });

    test('Success vs Failure are unequal', () {
      final s = SellConfirmSuccess();
      final f = SellConfirmFailure('boom');
      expect(s, isNot(equals(f)));
    });
  });
}
