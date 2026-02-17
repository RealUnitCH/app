import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/models/portfolio_value_point.dart';
import 'package:realunit_wallet/packages/utils/format_fixed.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/portfolio_chart/portfolio_chart_cubit.dart';
import 'package:realunit_wallet/screens/dashboard/models/time_period.dart';
import 'package:realunit_wallet/screens/dashboard/widgets/portfolio_chart.dart';
import 'package:realunit_wallet/screens/dashboard/widgets/time_period_selection_button.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/styles/colors.dart';

class DashboardPortfolioChartWidget extends StatelessWidget {
  final BigInt currentValue; // current balance × current price
  final List<PortfolioValuePoint> portfolioHistory;

  const DashboardPortfolioChartWidget({
    super.key,
    required this.currentValue,
    required this.portfolioHistory,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(portfolioHistory.hashCode),
      create: (context) => PortfolioChartCubit(portfolioHistory),
      child: DashboardPortfolioChartView(
        currentValue: currentValue,
        portfolioHistory: portfolioHistory,
      ),
    );
  }
}

class DashboardPortfolioChartView extends StatelessWidget {
  final BigInt currentValue; // current balance × current price
  final List<PortfolioValuePoint> portfolioHistory;

  const DashboardPortfolioChartView({
    super.key,
    required this.currentValue,
    required this.portfolioHistory,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 8),
    width: double.infinity,
    child: SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            child: Column(
              children: [
                const Row(
                  children: [
                    Text(
                      'Depotentwicklung',
                      style: TextStyle(
                        fontSize: 12,
                        color: RealUnitColors.neutral400,
                        height: 16 / 12,
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BlocBuilder<SettingsBloc, SettingsState>(
                      builder: (context, state) {
                        return Text(
                          state.currency.code.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: RealUnitColors.realUnitBlack,
                          ),
                        );
                      },
                    ),
                    Text(
                      formatFixed(currentValue, 2, trimZeros: false),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        color: RealUnitColors.realUnitBlack,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const PortfolioChart(),
          BlocBuilder<PortfolioChartCubit, PortfolioChartState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: TimePeriod.values.map((period) {
                    return Expanded(
                      child: TimePeriodSelectionButton(
                        period.name(context).toUpperCase(),
                        isSelected: state.selectedPeriod == period,
                        onTap: () => context.read<PortfolioChartCubit>().selectPeriod(period),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}
