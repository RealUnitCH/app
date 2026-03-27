import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/balance_cubit.dart';
import 'package:realunit_wallet/screens/dashboard/widgets/cash_holding_box.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/styles/colors.dart';

class DashboardPortfolio extends StatelessWidget {
  final BigInt price;

  const DashboardPortfolio({super.key, required this.price});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8.0,
      children: [
        Text(
          S.of(context).portfolio,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: RealUnitColors.basic.black,
          ),
        ),
        BlocBuilder<BalanceCubit, Balance>(
          builder: (context, state) => CashHoldingBox(
            asset: context.read<BalanceCubit>().asset,
            balance: state.balance,
            trailingSymbol: context.read<SettingsBloc>().state.currency.code.toUpperCase(),
            leadingSymbol: '',
            price: price,
          ),
        ),
      ],
    );
  }
}
