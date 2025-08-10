import 'package:deuro_wallet/generated/i18n.dart';
import 'package:deuro_wallet/packages/utils/default_assets.dart';
import 'package:deuro_wallet/packages/utils/format_fixed.dart';
import 'package:deuro_wallet/screens/savings/bloc/savings_bloc.dart';
import 'package:deuro_wallet/styles/colors.dart';
import 'package:deuro_wallet/styles/icons.dart';
import 'package:deuro_wallet/styles/styles.dart';
import 'package:deuro_wallet/widgets/action_button.dart';
import 'package:deuro_wallet/widgets/chain_asset_icon.dart';
import 'package:deuro_wallet/widgets/hide_amount_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SectionBalance extends StatelessWidget {
  final BigInt balance;
  final BigInt interestRate;
  final BigInt collectedInterest;
  final bool isEnabled;

  const SectionBalance({
    super.key,
    required this.balance,
    required this.interestRate,
    required this.collectedInterest,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: DEuroColors.dEuroBlue,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: Colors.white.withAlpha(50),
                      child: IconButton(
                        color: Colors.white,
                        onPressed: () => context.pop(),
                        iconSize: 18,
                        icon: const Icon(Icons.arrow_back_ios_new),
                      ),
                    ),
                    Spacer(),
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: Colors.white.withAlpha(50),
                      child: IconButton(
                        color: Colors.white,
                        onPressed: () => context.push('/settings'),
                        iconSize: 18,
                        icon: const Icon(Icons.settings),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 12, bottom: 12),
                child: Column(
                  children: [
                    Text(
                      "${S.of(context).savings_balance} | ${formatFixed(interestRate, 4, fractionalDigits: 2)}% APR",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withAlpha(153),
                      ),
                    ),
                    HideAmountText(
                      amount: balance,
                      style: const TextStyle(
                        fontSize: 35,
                        color: Colors.white,
                        fontFamily: "Satoshi Bold",
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: isEnabled
                    ? [
                        ActionButton(
                          icon: Icons.add,
                          label: S.of(context).savings_add,
                          onPressed: () => context.push('/savings/add'),
                          buttonStyle: kBalanceBarActionButtonStyle,
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 15),
                          child: ActionButton(
                            icon: Icons.remove,
                            label: S.of(context).savings_remove,
                            onPressed: () => context.push('/savings/remove'),
                            buttonStyle: kBalanceBarActionButtonStyle,
                          ),
                        ),
                      ]
                    : [
                        ActionButton(
                          icon: Icons.savings,
                          label: S.of(context).savings_enable,
                          onPressed: () =>
                              context.read<SavingsBloc>().add(EnableSavings()),
                          buttonStyle: kBalanceBarActionButtonStyle,
                        ),
                      ],
              ),
              Container(
                margin: const EdgeInsets.only(
                    left: 16, right: 16, bottom: 20, top: 36),
                padding: const EdgeInsets.only(
                    left: 16, right: 16, bottom: 20, top: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color.fromARGB(255, 54, 65, 198),
                ),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context).interest_to_be_collected,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withAlpha(153),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ChainAssetIcon(asset: dEUROAsset),
                          ),
                          HideAmountText(
                            amount: collectedInterest,
                            leadingSymbol: "",
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontFamily: "Satoshi Bold",
                            ),
                          ),
                          Spacer(),
                          ActionButton(
                            customIcon:
                                Icon(Icons.refresh, color: Colors.white),
                            label: S.of(context).savings_reinvest,
                            onPressed: isEnabled
                                ? () => context
                                    .read<SavingsBloc>()
                                    .add(CompoundInterest())
                                : null,
                            buttonStyle: kBalanceBarActionButtonStyle,
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: ActionButton(
                              customIcon:
                                  CollectInterestIcon(color: Colors.white),
                              label: S.of(context).collect_interest,
                              onPressed: isEnabled
                                  ? () => context
                                      .read<SavingsBloc>()
                                      .add(CollectInterest())
                                  : null,
                              buttonStyle: kBalanceBarActionButtonStyle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      );
}
