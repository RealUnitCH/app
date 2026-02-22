import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/repository/balance_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_price_service.dart';
import 'package:realunit_wallet/screens/buy/buy_page.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/balance_cubit.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/dashboard_bloc.dart';
import 'package:realunit_wallet/screens/dashboard/widgets/sections/dashboard_actions.dart';
import 'package:realunit_wallet/screens/dashboard/widgets/sections/dashboard_portfolio.dart';
import 'package:realunit_wallet/screens/dashboard/widgets/sections/dashboard_price_widget.dart';
import 'package:realunit_wallet/screens/dashboard/widgets/sections/dashboard_transaction_history.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/icons.dart';

class DashboardPage extends StatelessWidget {
  static const routeName = '/dashboard';

  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => DashboardBloc(
            getIt<DFXPriceService>(),
            asset: getIt<AppStore>().apiConfig.asset,
            initialCurrency: context.read<SettingsBloc>().state.currency,
          ),
        ),
        BlocProvider(
          create: (context) => BalanceCubit(
            getIt<BalanceRepository>(),
            asset: getIt<AppStore>().apiConfig.asset,
            walletAddress: getIt<AppStore>().primaryAddress,
          ),
        ),
      ],
      child: const DashboardView(),
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final isFiatServiceAvailable = context.watch<HomeBloc>().state.isFiatServiceAvailable;
    final dashboardState = context.watch<DashboardBloc>().state;
    final balance = context.watch<BalanceCubit>().state.balance;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: SafeArea(
          child: Row(
            spacing: 6.0,
            children: [
              const SizedBox(width: 14),
              const RealUnitIcon(),
              Expanded(
                child: Text(
                  S.of(context).realunitWallet,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.32,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => context.push('/settings'),
                icon: const Icon(
                  Icons.menu,
                  color: RealUnitColors.realUnitBlue,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
      body: BlocListener<SettingsBloc, SettingsState>(
        listenWhen: (previous, current) => previous.currency != current.currency,
        listener: (context, state) {
          context.read<DashboardBloc>().add(CurrencyChangedEvent(state.currency));
        },
        child: PopScope(
          canPop: false,
          child: Column(
            children: [
              DashboardPriceWidget(
                price: dashboardState.price,
                priceChart: dashboardState.priceChart,
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(color: RealUnitColors.neutral100),
                    if (balance > BigInt.zero)
                      SingleChildScrollView(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 24.0,
                          ),
                          child: Column(
                            spacing: 20.0,
                            children: [
                              if (isFiatServiceAvailable) const DashboardActions(),
                              DashboardPortfolio(
                                price: dashboardState.price,
                              ),
                              const DashboardTransactionHistory(),
                            ],
                          ),
                        ),
                      )
                    else
                      Align(
                        alignment: .topCenter,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 24.0,
                          ),
                          child: Column(
                            children: [
                              const Spacer(),
                              SvgPicture.asset(
                                'assets/images/add-realu-token-visual.svg',
                                width: 165,
                                height: 165,
                              ),
                              const Spacer(),
                              if (isFiatServiceAvailable)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: () => context.push(BuyPage.routeName),
                                      child: Text(S.of(context).buy),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
