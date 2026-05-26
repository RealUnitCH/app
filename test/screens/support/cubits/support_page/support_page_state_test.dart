// We deliberately use non-const constructors throughout this file so the
// generative constructor lines get counted as executed in the coverage
// report. Const-only construction is a compile-time optimisation and is
// not visible to the line-coverage instrumentation.
// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/support/cubits/support_page/support_page_cubit.dart';

/// Equatable-`props` surface tests for `SupportPageState`.
void main() {
  group('SupportPageIdle', () {
    test('two instances are equal and props are empty', () {
      final a = SupportPageIdle();
      final b = SupportPageIdle();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.props, isEmpty);
    });
  });

  group('SupportPageNavigating', () {
    test('two instances are equal and props are empty', () {
      final a = SupportPageNavigating();
      final b = SupportPageNavigating();
      expect(a, equals(b));
      expect(a.props, isEmpty);
    });
  });

  group('SupportPageNavigateToCreate', () {
    test('two instances are equal and props are empty', () {
      final a = SupportPageNavigateToCreate();
      final b = SupportPageNavigateToCreate();
      expect(a, equals(b));
      expect(a.props, isEmpty);
    });
  });

  group('SupportPageNavigateToEmailThenCreate', () {
    test('two instances are equal and props are empty', () {
      final a = SupportPageNavigateToEmailThenCreate();
      final b = SupportPageNavigateToEmailThenCreate();
      expect(a, equals(b));
      expect(a.props, isEmpty);
    });
  });

  group('SupportPageNavigationFailure', () {
    test('same message is equal and props match', () {
      final a = SupportPageNavigationFailure(message: 'boom');
      final b = SupportPageNavigationFailure(message: 'boom');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.props, ['boom']);
    });

    test('different messages are unequal', () {
      final a = SupportPageNavigationFailure(message: 'boom');
      final b = SupportPageNavigationFailure(message: 'other');
      expect(a, isNot(equals(b)));
    });
  });

  group('SupportPageState (cross-subclass identity)', () {
    test('Idle vs Navigating are unequal even though props match', () {
      expect(SupportPageIdle(), isNot(equals(SupportPageNavigating())));
    });

    test('NavigateToCreate vs NavigateToEmailThenCreate are unequal', () {
      expect(
        SupportPageNavigateToCreate(),
        isNot(equals(SupportPageNavigateToEmailThenCreate())),
      );
    });

    test('NavigateToCreate vs NavigationFailure are unequal', () {
      expect(
        SupportPageNavigateToCreate(),
        isNot(equals(SupportPageNavigationFailure(message: 'x'))),
      );
    });
  });
}
