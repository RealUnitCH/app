import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/models/blockchain.dart';
import 'package:realunit_wallet/models/transaction.dart';
import 'package:realunit_wallet/packages/repository/balance_repository.dart';
import 'package:realunit_wallet/packages/repository/transaction_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_service.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/aggregated_balance_cubit.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/blance_cubit.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/transaction_history_cubit.dart';
import 'package:realunit_wallet/screens/dashboard/widgets/cash_holding_box.dart';
import 'package:realunit_wallet/screens/dashboard/widgets/section_balance.dart';
import 'package:realunit_wallet/screens/dashboard/widgets/section_transaction_history.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/icons.dart';
import 'package:realunit_wallet/styles/styles.dart';
import 'package:realunit_wallet/widgets/action_button.dart';

class DashboardPage extends StatelessWidget {
  DashboardPage(this._appStore, {super.key}) {
    aggregatedDEuro = AggregatedBalanceCubit(getIt<BalanceRepository>(), [
      dEUROAsset.getEmptyBalance(walletAddress),
      dEUROBaseAsset.getEmptyBalance(walletAddress),
      dEUROOptimismAsset.getEmptyBalance(walletAddress),
      dEUROArbitrumAsset.getEmptyBalance(walletAddress),
      dEUROPolygonAsset.getEmptyBalance(walletAddress),
    ]);

    for (final asset in [
      dEUROAsset,
      dEUROBaseAsset,
      dEUROOptimismAsset,
      dEUROArbitrumAsset,
      dEUROPolygonAsset,
    ]) {
      singleCashHoldings.add(BalanceCubit(getIt<BalanceRepository>(),
          asset: asset, walletAddress: walletAddress));
    }

    for (final asset in [
      depsAsset,
      nDEPSAsset,
      Blockchain.ethereum.nativeAsset,
      Blockchain.polygon.nativeAsset,
      Blockchain.base.nativeAsset,
      Blockchain.optimism.nativeAsset,
      Blockchain.arbitrum.nativeAsset,
    ]) {
      cryptoHoldings.add(BalanceCubit(getIt<BalanceRepository>(),
          asset: asset, walletAddress: walletAddress));
    }

    transactionHistoryCubit =
        TransactionHistoryCubit(getIt<TransactionRepository>(), walletAddress);
  }

  final AppStore _appStore;

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
          ...singleCashHoldings.map((cubit) => BlocProvider.value(value: cubit))
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
              "Real Unit Wallet",
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
          body: SafeArea(
            top: false,
            child: PopScope(
              canPop: false,
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    BlocBuilder<HomeBloc, HomeState>(
                      bloc: context.read<HomeBloc>(),
                      builder: (context, homeState) => BlocBuilder<
                          AggregatedBalanceCubit, AggregatedBalance>(
                        bloc: aggregatedDEuro,
                        builder: (context, state) => SectionBalance(
                          balance: state.balance,
                          isFiatServiceAvailable:
                              homeState.isFiatServiceAvailable,
                          onHideAmountPress: () => context
                              .read<SettingsBloc>()
                              .add(ToggleHideAmountEvent()),
                          onDepositPress: () =>
                              getIt<DFXService>().launchProvider(context, true),
                          onWithdrawPress: () => getIt<DFXService>()
                              .launchProvider(context, false),
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
                                      child: BlocBuilder<
                                          TransactionHistoryCubit,
                                          List<Transaction>>(
                                        bloc: transactionHistoryCubit,
                                        builder: (context, state) =>
                                            SectionTransactionHistory(
                                          transactions: state,
                                          walletAddress: walletAddress,
                                          hasShowAll: state.length == 5,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                "Cash Holdings",
                                                style: kSubtitleTextStyle,
                                              ),
                                              Spacer(),
                                              // ActionButton(
                                              //   icon: Icons.currency_exchange,
                                              //   label: "Swap",
                                              //   onPressed: () =>
                                              //       context.push('/swap'),
                                              //   textStyle:
                                              //       kActionButtonTextStyle
                                              //           .copyWith(
                                              //     color:
                                              //         DEuroColors.neutralGrey,
                                              //   ),
                                              // ),
                                              ActionButton(
                                                icon: Icons.savings,
                                                label: "Savings",
                                                onPressed: () =>
                                                    context.push('/savings'),
                                                textStyle:
                                                    kActionButtonTextStyle
                                                        .copyWith(
                                                  color:
                                                      DEuroColors.neutralGrey,
                                                ),
                                              ),
                                            ],
                                          ),
                                          ...singleCashHoldings.map(
                                            (holding) => BlocBuilder<
                                                BalanceCubit, Balance>(
                                              bloc: holding,
                                              builder: (context, state) =>
                                                  Offstage(
                                                offstage: state.balance ==
                                                    BigInt.zero,
                                                child: CashHoldingBox(
                                                  asset: holding.asset,
                                                  balance: state.balance,
                                                ),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                "Crypto Holdings",
                                                style: kSubtitleTextStyle,
                                              ),
                                              Spacer(),
                                              // ActionButton(
                                              //   icon: Icons.show_chart,
                                              //   label: "Invest",
                                              //   onPressed: () =>
                                              //       context.push('/invest'),
                                              //   textStyle:
                                              //   kActionButtonTextStyle
                                              //       .copyWith(
                                              //     color:
                                              //     DEuroColors.neutralGrey,
                                              //   ),
                                              // ),
                                            ],
                                          ),
                                          MultiBlocProvider(
                                            providers: cryptoHoldings
                                                .map((cubit) =>
                                                    BlocProvider.value(
                                                        value: cubit))
                                                .toList(),
                                            child: Column(
                                              children: cryptoHoldings
                                                  .map(
                                                    (holding) => BlocBuilder<
                                                        BalanceCubit, Balance>(
                                                      bloc: holding,
                                                      builder:
                                                          (context, state) =>
                                                              Offstage(
                                                        offstage:
                                                            state.balance ==
                                                                BigInt.zero,
                                                        child: CashHoldingBox(
                                                          backgroundColor:
                                                              DEuroColors
                                                                  .neutralGrey93,
                                                          asset: holding.asset,
                                                          balance:
                                                              state.balance,
                                                          leadingSymbol: "",
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
      );
}
