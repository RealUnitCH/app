import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/packages/utils/format_fixed.dart';
import 'package:realunit_wallet/screens/dashboard/widgets/cash_holding_box.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/styles.dart';
import 'package:realunit_wallet/widgets/chain_asset_icon.dart';
import 'package:realunit_wallet/widgets/handlebars.dart';

class AssetSelector extends StatelessWidget {
  const AssetSelector({
    super.key,
    required this.onPressed,
    required this.selectedBalance,
    required this.availableBalances,
    this.padding,
  });

  final void Function(Asset asset) onPressed;
  final EdgeInsetsGeometry? padding;
  final Balance selectedBalance;
  final List<Balance> availableBalances;

  Future<void> _openSelector(BuildContext context) async {
    showCupertinoSheet(
      context: context,
      builder: (context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 16),
              child: Handlebars.horizontal(context),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    S.of(context).select_token,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                ...availableBalances.map(
                  (balance) => Padding(
                    padding: const EdgeInsets.all(2.5),
                    child: GestureDetector(
                      onTap: () {
                        onPressed.call(balance.asset);
                        context.pop();
                      },
                      child: CashHoldingBox(
                        asset: balance.asset,
                        balance: balance.balance,
                        borderColor:
                            balance.id == selectedBalance.id ? RealUnitColors.realUnitBlue : null,
                      ),
                      // child: Container(
                      //   padding: const EdgeInsets.all(5),
                      //   decoration: BoxDecoration(
                      //     borderRadius: BorderRadius.circular(10),
                      //   ),
                      //   child: Row(
                      //     children: [
                      //       Padding(
                      //         padding: const EdgeInsets.only(right: 16),
                      //         child: ChainAssetIcon(asset: balance.asset),
                      //       ),
                      //       Expanded(
                      //         child: Column(
                      //           crossAxisAlignment: CrossAxisAlignment.start,
                      //           children: [
                      //             Text(
                      //               balance.asset.name,
                      //               style: kPageTitleTextStyle,
                      //             ),
                      //           ],
                      //         ),
                      //       ),
                      //       if (balance.id == selectedBalance.id)
                      //         Icon(Icons.check)
                      //     ],
                      //   ),
                      // ),
                    ),
                  ),
                ),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding ?? const EdgeInsets.only(top: 5, bottom: 5),
        child: InkWell(
          onTap: () => _openSelector(context),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ChainAssetIcon(asset: selectedBalance.asset),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${S.of(context).available}:',
                      style: kSubtitleTextStyle.copyWith(fontSize: 16),
                    ),
                    Text(
                      '${formatFixed(selectedBalance.balance, selectedBalance.asset.decimals, fractionalDigits: 2)} ${selectedBalance.asset.symbol}',
                      style: kPageTitleTextStyle,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 24,
              )
            ],
          ),
        ),
      );
}
