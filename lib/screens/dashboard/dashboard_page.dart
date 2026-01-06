import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/models/blockchain.dart';
import 'package:realunit_wallet/models/transaction.dart';
import 'package:realunit_wallet/packages/repository/balance_repository.dart';
import 'package:realunit_wallet/packages/repository/transaction_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/price_service.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/screens/buy/buy_page.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/aggregated_balance_cubit.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/balance_cubit.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/dashboard_bloc.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/transaction_history_cubit.dart';
import 'package:realunit_wallet/screens/dashboard/widgets/cash_holding_box.dart';
import 'package:realunit_wallet/screens/dashboard/widgets/price_widget.dart';
import 'package:realunit_wallet/screens/dashboard/widgets/section_transaction_history.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/icons.dart';
import 'package:realunit_wallet/styles/styles.dart';
import 'package:realunit_wallet/widgets/action_button.dart';

class DashboardPage extends StatelessWidget {
  DashboardPage(this._appStore, this._priceService, {super.key}) {
    aggregatedDEuro = AggregatedBalanceCubit(getIt<BalanceRepository>(), [
      dEUROAsset.getEmptyBalance(walletAddress),
      dEUROBaseAsset.getEmptyBalance(walletAddress),
      dEUROOptimismAsset.getEmptyBalance(walletAddress),
      dEUROArbitrumAsset.getEmptyBalance(walletAddress),
      dEUROPolygonAsset.getEmptyBalance(walletAddress),
    ]);

    for (final asset in [realUnitAsset]) {
      singleCashHoldings.add(BalanceCubit(
        getIt<BalanceRepository>(),
        asset: asset,
        walletAddress: walletAddress,
      ));
    }

    for (final asset in [
      Blockchain.ethereum.nativeAsset,
      Blockchain.polygon.nativeAsset,
      Blockchain.base.nativeAsset,
      Blockchain.optimism.nativeAsset,
      Blockchain.arbitrum.nativeAsset,
    ]) {
      cryptoHoldings.add(
          BalanceCubit(getIt<BalanceRepository>(), asset: asset, walletAddress: walletAddress));
    }

    transactionHistoryCubit =
        TransactionHistoryCubit(getIt<TransactionRepository>(), walletAddress, _appStore);
  }

  final AppStore _appStore;
  final APriceService _priceService;

  String get walletAddress => _appStore.primaryAddress;

  late final AggregatedBalanceCubit aggregatedDEuro;
  final List<BalanceCubit> singleCashHoldings = [];
  final List<BalanceCubit> cryptoHoldings = [];
  late final TransactionHistoryCubit transactionHistoryCubit;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: aggregatedDEuro),
          BlocProvider.value(value: transactionHistoryCubit),
          ...singleCashHoldings.map((cubit) => BlocProvider.value(value: cubit)),
          BlocProvider.value(
              value: DashboardBloc(_priceService,
                  asset: realUnitAsset, currency: context.read<SettingsBloc>().state.currency)),
        ],
        child: Scaffold(
          appBar: AppBar(
            leading: Padding(
              padding: EdgeInsets.only(left: 20),
              child: RealUnitIcon(),
            ),
            leadingWidth: 40,
            toolbarHeight: 68,
            titleSpacing: 6,
            title: Text(
              "RealUnit Wallet",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
            ),
            actions: [
              IconButton(
                onPressed: () => context.push('/settings'),
                icon: Icon(
                  Icons.menu,
                  color: RealUnitColors.realUnitBlue,
                ),
              )
            ],
          ),
          body: BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, dashboardState) => SafeArea(
              top: false,
              child: PopScope(
                canPop: false,
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      BlocBuilder<SettingsBloc, SettingsState>(
                        bloc: context.read<SettingsBloc>(),
                        builder: (context, settingsBloc) => PriceWidget(
                          currency: settingsBloc.currency,
                          price: dashboardState.price,
                          priceChart: dashboardState.priceChart,
                        ),
                      ),
                      BlocBuilder<HomeBloc, HomeState>(
                        builder: (context, homeState) => Offstage(
                          offstage: !homeState.isFiatServiceAvailable,
                          child: Padding(
                            padding: EdgeInsets.only(left: 16, right: 16, top: 24),
                            child: Row(
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(right: 10),
                                  child: ActionButton(
                                    icon: RealUnitTokenIcon(size: 20),
                                    label: S.of(context).buy,
                                    onPressed: () => context.push(BuyPage.routeName),
                                  ),
                                ),
                                ActionButton(
                                  icon: Icon(
                                    Icons.account_balance,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  label: S.of(context).sell,
                                  backgroundColor: RealUnitColors.neutral300,
                                  // onPressed: () =>
                                  //     getIt<DFXService>().launchProvider(context, false),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          alignment: AlignmentDirectional.bottomCenter,
                          children: [
                            CustomScrollView(
                              slivers: [
                                SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: Column(
                                    children: <Widget>[
                                      Padding(
                                        padding: EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              S.of(context).portfolio,
                                              style: kSubtitleTextStyle,
                                            ),
                                            ...singleCashHoldings.map(
                                              (holding) => BlocBuilder<BalanceCubit, Balance>(
                                                bloc: holding,
                                                builder: (context, state) => CashHoldingBox(
                                                  asset: holding.asset,
                                                  balance: state.balance,
                                                  trailingSymbol: context
                                                      .read<SettingsBloc>()
                                                      .state
                                                      .currency
                                                      .code
                                                      .toUpperCase(),
                                                  leadingSymbol: "",
                                                  price: dashboardState.price,
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      Padding(
                                          padding: EdgeInsets.all(20),
                                          child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  S.of(context).transactions,
                                                  style: kSubtitleTextStyle,
                                                ),
                                                BlocBuilder<TransactionHistoryCubit,
                                                    List<Transaction>>(
                                                  bloc: transactionHistoryCubit,
                                                  builder: (context, state) =>
                                                      SectionTransactionHistory(
                                                    transactions: state,
                                                    walletAddress: walletAddress,
                                                    hasShowAll: state.length == 5,
                                                  ),
                                                ),
                                              ])),
                                    ],
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
            ),
          ),
        ),
      );
}
