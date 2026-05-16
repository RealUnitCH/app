import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/models/price_point.dart';
import 'package:realunit_wallet/models/portfolio_value_point.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/dashboard_bloc.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/portfolio_chart/portfolio_chart_cubit.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/price_chart/price_chart_state.dart';
import 'package:realunit_wallet/screens/dashboard/models/time_period.dart';
import 'package:realunit_wallet/screens/legal/cubit/legal_disclaimer_cubit.dart';
import 'package:realunit_wallet/styles/currency.dart';

void main() {
  group('$DashboardState', () {
    final base = DashboardState(
      price: BigInt.from(100),
      priceChart: const <PricePoint>[],
      portfolioHistory: const <PortfolioValuePoint>[],
      currency: Currency.chf,
    );

    test('copyWith preserves untouched fields', () {
      final next = base.copyWith(currency: Currency.eur);
      expect(next.price, base.price);
      expect(next.currency, Currency.eur);
    });

    test('Equatable props pin price + chart + history + currency', () {
      final a = DashboardState(
        price: BigInt.from(100),
        priceChart: const [],
        portfolioHistory: const [],
        currency: Currency.chf,
      );
      final b = DashboardState(
        price: BigInt.from(100),
        priceChart: const [],
        portfolioHistory: const [],
        currency: Currency.chf,
      );
      final c = base.copyWith(price: BigInt.from(200));
      expect(a, b);
      expect(a, isNot(c));
    });
  });

  group('$LegalDisclaimerState', () {
    test('totalSteps constant is 5', () {
      expect(LegalDisclaimerState.totalSteps, 5);
    });

    test('default state: currentStep=0, !canGoBack, !isLastStep, progress=0.2', () {
      const state = LegalDisclaimerState();
      expect(state.currentStep, 0);
      expect(state.canGoBack, isFalse);
      expect(state.isLastStep, isFalse);
      expect(state.progress, closeTo(0.2, 1e-9));
    });

    test('currentStep=4 (last): canGoBack + isLastStep + progress=1.0', () {
      const state = LegalDisclaimerState(currentStep: 4);
      expect(state.canGoBack, isTrue);
      expect(state.isLastStep, isTrue);
      expect(state.progress, closeTo(1.0, 1e-9));
    });

    test('copyWith preserves untouched field', () {
      const base = LegalDisclaimerState(currentStep: 2);
      final next = base.copyWith();
      expect(next.currentStep, 2);
    });

    test('Equatable props pin currentStep only', () {
      expect(
        const LegalDisclaimerState(currentStep: 1),
        const LegalDisclaimerState(currentStep: 1),
      );
      expect(
        const LegalDisclaimerState(currentStep: 1),
        isNot(const LegalDisclaimerState(currentStep: 2)),
      );
    });
  });

  group('$PriceChartState', () {
    const base = PriceChartState(
      selectedPeriod: TimePeriod.oneWeek,
      visibleSpots: <FlSpot>[],
      minX: 0,
      maxX: 1,
      minY: 0,
      maxY: 1,
    );

    test('copyWith preserves untouched fields', () {
      final next = base.copyWith(selectedPeriod: TimePeriod.oneMonth);
      expect(next.selectedPeriod, TimePeriod.oneMonth);
      expect(next.minX, base.minX);
      expect(next.visibleSpots, base.visibleSpots);
    });

    test('Equatable props pin all six fields', () {
      expect(base, base.copyWith());
      expect(base, isNot(base.copyWith(maxY: 2)));
    });
  });

  group('$PortfolioChartState', () {
    const base = PortfolioChartState(
      selectedPeriod: TimePeriod.oneWeek,
      visibleSpots: <FlSpot>[],
      minX: 0,
      maxX: 1,
      minY: 0,
      maxY: 1,
      horizontalLineValues: <double>[],
    );

    test('copyWith preserves untouched fields', () {
      final next = base.copyWith(horizontalLineValues: const [1.0, 2.0]);
      expect(next.selectedPeriod, base.selectedPeriod);
      expect(next.horizontalLineValues, const [1.0, 2.0]);
    });

    test('Equatable props pin horizontalLineValues', () {
      expect(base, base.copyWith());
      expect(base, isNot(base.copyWith(horizontalLineValues: const [1.0])));
    });
  });
}
