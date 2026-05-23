// We deliberately use non-const constructors throughout this file so the
// generative constructor lines get counted as executed in the coverage
// report. Const-only construction is a compile-time optimisation and is
// not visible to the line-coverage instrumentation.
// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/dashboard_bloc.dart';
import 'package:realunit_wallet/styles/currency.dart';

/// Equatable-`props` surface tests for `DashboardEvent`.
void main() {
  group('RefreshPriceEvent', () {
    test('two instances are equal and props are empty', () {
      final a = RefreshPriceEvent();
      final b = RefreshPriceEvent();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.props, isEmpty);
    });
  });

  group('RefreshPriceChartEvent', () {
    test('two instances are equal and props are empty', () {
      final a = RefreshPriceChartEvent();
      final b = RefreshPriceChartEvent();
      expect(a, equals(b));
      expect(a.props, isEmpty);
    });
  });

  group('RefreshPortfolioHistoryEvent', () {
    test('two instances are equal and props are empty', () {
      final a = RefreshPortfolioHistoryEvent();
      final b = RefreshPortfolioHistoryEvent();
      expect(a, equals(b));
      expect(a.props, isEmpty);
    });
  });

  group('CurrencyChangedEvent', () {
    test('same currency is equal and props match', () {
      final a = CurrencyChangedEvent(Currency.chf);
      final b = CurrencyChangedEvent(Currency.chf);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.props, [Currency.chf]);
    });

    test('different currencies are unequal', () {
      final a = CurrencyChangedEvent(Currency.chf);
      final b = CurrencyChangedEvent(Currency.eur);
      expect(a, isNot(equals(b)));
    });
  });

  group('DashboardEvent (cross-subclass identity)', () {
    test('different payload-less subclasses are not equal', () {
      // All three Refresh*Event variants inherit `props => []` from the
      // sealed base. Equatable's runtimeType check separates them.
      expect(RefreshPriceEvent(), isNot(equals(RefreshPriceChartEvent())));
      expect(RefreshPriceChartEvent(), isNot(equals(RefreshPortfolioHistoryEvent())));
      expect(RefreshPriceEvent(), isNot(equals(RefreshPortfolioHistoryEvent())));
    });
  });
}
