import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/buy/buy_page.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/sell/sell_page.dart';
import 'package:realunit_wallet/styles/icons.dart';
import 'package:realunit_wallet/widgets/action_button.dart';

class DashboardActions extends StatelessWidget {
  const DashboardActions({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, homeState) => Offstage(
        offstage: !homeState.isFiatServiceAvailable,
        child: Row(
          spacing: 10,
          children: [
            ActionButton(
              icon: const RealUnitTokenIcon(size: 20),
              label: S.of(context).buy,
              onPressed: () => context.push(BuyPage.routeName),
            ),
            ActionButton(
              icon: const Icon(
                Icons.account_balance,
                color: Colors.white,
                size: 20,
              ),
              label: S.of(context).sell,
              onPressed: () => context.push(SellPage.routeName),
            ),
          ],
        ),
      ),
    );
  }
}
