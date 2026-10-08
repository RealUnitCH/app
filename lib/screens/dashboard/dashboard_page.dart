import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/repository/balance_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_price_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_account_service.dart';
import 'package:realunit_wallet/packages/service/transaction_history_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/balance_cubit.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/dashboard_bloc.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/pending_transactions_cubit.dart';
import 'package:realunit_wallet/screens/dashboard/widgets/sections/dashboard_actions.dart';
import 'package:realunit_wallet/screens/dashboard/widgets/sections/dashboard_pending_transactions.dart';
import 'package:realunit_wallet/screens/dashboard/widgets/sections/dashboard_portfolio.dart';
import 'package:realunit_wallet/screens/dashboard/widgets/sections/dashboard_portfolio_chart_widget.dart';
import 'package:realunit_wallet/screens/dashboard/widgets/sections/dashboard_price_widget.dart';
import 'package:realunit_wallet/screens/dashboard/widgets/sections/dashboard_transaction_history.dart';
import 'package:realunit_wallet/screens/dashboard/widgets/update_available_banner.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/referral/widgets/referral_entry_card.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/setup/routing/routes/settings_routes.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/icons.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/scrollable_actions_layout.dart';
import 'package:realunit_wallet/widgets/tab_selector.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Future<List<AWallet>>? _wallets;
  int? _walletsOpenWalletId;
  var _hasWalletsFuture = false;

  @override
  Widget build(BuildContext context) {
    final networkMode = context.watch<SettingsBloc>().state.networkMode;
    final openWallet = context.watch<HomeBloc>().state.openWallet;
    final address = openWallet?.currentAccount.primaryAddress.address.hex;
    final openWalletId = openWallet?.id;
    // Replace the list future when the open wallet id changes so a deleted row cannot stay cached.
    if (!_hasWalletsFuture || _walletsOpenWalletId != openWalletId) {
      _wallets = getIt<WalletService>().listWallets();
      _walletsOpenWalletId = openWalletId;
      _hasWalletsFuture = true;
    }

    return FutureBuilder<List<AWallet>>(
      future: _wallets,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          throw snapshot.error!;
        }
        final List<AWallet> wallets;
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          wallets = snapshot.data!;
        } else {
          wallets = const <AWallet>[];
        }
        return MultiBlocProvider(
          key: ValueKey('$networkMode-$address'),
          providers: [
            BlocProvider(
              create: (context) => DashboardBloc(
                getIt<DFXPriceService>(),
                getIt<RealUnitAccountService>(),
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
            BlocProvider(
              create: (context) => PendingTransactionsCubit(
                getIt<TransactionHistoryService>(),
              ),
            ),
          ],
          child: DashboardView(wallets: wallets),
        );
      },
    );
  }
}

bool showWalletSwitcher(List<AWallet> wallets) {
  var software = 0;
  var bitbox = 0;
  for (final wallet in wallets) {
    if (wallet.walletType == WalletType.software) {
      software += 1;
    } else if (wallet.walletType == WalletType.bitbox) {
      bitbox += 1;
    }
  }
  return software == 1 && bitbox == 1 && wallets.length == 2;
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key, this.wallets = const []});

  final List<AWallet> wallets;

  @override
  Widget build(BuildContext context) {
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
              Expanded(child: _DashboardTitle(wallets: wallets)),
              IconButton(
                onPressed: () => context.pushNamed(SettingsRoutes.settings),
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
              if (dashboardState.portfolioHistory.isNotEmpty)
                DashboardPortfolioChartWidget(
                  currentValue: dashboardState.portfolioHistory.isNotEmpty
                      ? dashboardState.portfolioHistory.last.balance * dashboardState.price
                      : BigInt.zero,
                  portfolioHistory: dashboardState.portfolioHistory,
                )
              else
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
                          padding: const .symmetric(
                            horizontal: 20.0,
                            vertical: 24.0,
                          ),
                          child: Column(
                            spacing: 20.0,
                            children: [
                              const UpdateAvailableBanner(),
                              const DashboardActions(),
                              const ReferralEntryCard(),
                              DashboardPortfolio(
                                price: dashboardState.price,
                              ),
                              const DashboardPendingTransactionsView(),
                              const DashboardTransactionHistory(),
                            ],
                          ),
                        ),
                      )
                    else
                      ScrollableActionsLayout(
                        padding: const .symmetric(
                          horizontal: 20.0,
                          vertical: 24.0,
                        ),
                        centerBody: true,
                        body: Column(
                          crossAxisAlignment: .stretch,
                          spacing: context.watch<PendingTransactionsCubit>().state.isEmpty
                              ? 0.0
                              : 24.0,
                          children: [
                            const UpdateAvailableBanner(),
                            const DashboardPendingTransactionsView(),
                            SvgPicture.asset(
                              'assets/images/illustrations/realu_token.svg',
                              width: 165,
                              height: 165,
                            ),
                          ],
                        ),
                        actions: [
                          Padding(
                            padding: const .symmetric(vertical: 20),
                            child: AppFilledButton(
                              onPressed: () => context.pushNamed(AppRoutes.buy),
                              label: S.of(context).buyRealUnit,
                            ),
                          ),
                        ],
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

class _DashboardTitle extends StatelessWidget {
  const _DashboardTitle({required this.wallets});

  final List<AWallet> wallets;

  @override
  Widget build(BuildContext context) {
    if (!showWalletSwitcher(wallets)) {
      return Text(
        S.of(context).realunitWallet,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.32,
        ),
      );
    }
    final openWallet = context.watch<HomeBloc>().state.openWallet;
    if (openWallet == null) {
      return Text(
        S.of(context).realunitWallet,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.32,
        ),
      );
    }
    return TabSelector<WalletType>(
      tabs: const [WalletType.software, WalletType.bitbox],
      selectedTab: openWallet.walletType,
      onTabSelected: (type) {
        if (type == openWallet.walletType) {
          return;
        }
        AWallet? target;
        for (final wallet in wallets) {
          if (wallet.walletType == type) {
            target = wallet;
            break;
          }
        }
        if (target == null) {
          return;
        }
        context.read<HomeBloc>().add(SwitchWalletEvent(target.id));
      },
      labelBuilder: (context, type, isSelected) {
        final label = type == WalletType.software
            ? S.of(context).walletSwitcherSoftware
            : S.of(context).walletSwitcherBitbox;
        return Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        );
      },
    );
  }
}
