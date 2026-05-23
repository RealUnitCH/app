// We deliberately use non-const constructors throughout this file so the
// generative constructor lines get counted as executed in the coverage
// report. Const-only construction is a compile-time optimisation and is
// not visible to the line-coverage instrumentation.
// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/settings_tax_report/cubit/settings_tax_report_cubit.dart';

/// Equatable-`props` surface tests for `SettingsTaxReportState`.
///
/// Note: `SettingsTaxReportFailure` deliberately does NOT override `props`
/// — it inherits the empty list from the base class. The test below pins
/// that asymmetry, because a future refactor that adds `props => [message]`
/// would change observable equality semantics.
void main() {
  group('SettingsTaxReportInitial', () {
    test('two instances are equal and props are empty', () {
      final a = SettingsTaxReportInitial();
      final b = SettingsTaxReportInitial();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.props, isEmpty);
    });
  });

  group('SettingsTaxReportLoading', () {
    test('two instances are equal and props are empty', () {
      final a = SettingsTaxReportLoading();
      final b = SettingsTaxReportLoading();
      expect(a, equals(b));
      expect(a.props, isEmpty);
    });
  });

  group('SettingsTaxReportSuccess', () {
    test('same taxReportPath is equal and props match', () {
      final a = SettingsTaxReportSuccess('/tmp/tax.pdf');
      final b = SettingsTaxReportSuccess('/tmp/tax.pdf');
      expect(a, equals(b));
      expect(a.props, ['/tmp/tax.pdf']);
    });

    test('different paths are unequal', () {
      final a = SettingsTaxReportSuccess('/tmp/a.pdf');
      final b = SettingsTaxReportSuccess('/tmp/b.pdf');
      expect(a, isNot(equals(b)));
    });
  });

  group('SettingsTaxReportFailure', () {
    test('does not override props → all failures compare equal', () {
      // Failure inherits `props => []`. Two failures with different
      // messages are still equal by Equatable's rules. Document and pin
      // that behaviour so it stays intentional.
      final a = SettingsTaxReportFailure('boom');
      final b = SettingsTaxReportFailure('other');
      expect(a, equals(b));
      expect(a.message, 'boom');
      expect(b.message, 'other');
      expect(a.props, isEmpty);
    });
  });

  group('SettingsTaxReportState (cross-subclass identity)', () {
    test('Initial vs Loading are unequal', () {
      expect(SettingsTaxReportInitial(), isNot(equals(SettingsTaxReportLoading())));
    });

    test('Success vs Failure are unequal even with same conceptual payload', () {
      final s = SettingsTaxReportSuccess('/tmp/x.pdf');
      final f = SettingsTaxReportFailure('/tmp/x.pdf');
      // Different runtimeType → unequal regardless of payload coincidence.
      expect(s, isNot(equals(f)));
    });
  });
}
