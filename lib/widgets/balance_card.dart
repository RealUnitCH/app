import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/packages/utils/asset_logo.dart';
import 'package:realunit_wallet/packages/utils/format_fixed.dart';
import 'package:realunit_wallet/styles/styles.dart';
import 'package:realunit_wallet/widgets/primary_button.dart';
import 'package:flutter/material.dart';

class BalanceCard extends StatelessWidget {
  final Asset asset;
  final BigInt balance;
  final String? actionLabel;
  final void Function()? action;
  final Color backgroundColor;
  final bool showBlockchainIcon;
  final bool navigateToDetails;

  const BalanceCard({
    super.key,
    required this.asset,
    required this.balance,
    this.actionLabel,
    this.action,
    this.backgroundColor = Colors.white10,
    this.showBlockchainIcon = false,
    this.navigateToDetails = true,
  });

  String get leadingImagePath => getAssetImagePath(asset);

  @override
  Widget build(BuildContext context) => InkWell(
        child: Container(
          margin: const EdgeInsets.only(left: 10, right: 10, top: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: backgroundColor,
          ),
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(leadingImagePath, width: 40),
                  Expanded(
                      child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                asset.name,
                                style: kPageTitleTextStyle.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                asset.symbol,
                                style: const TextStyle(color: Colors.white),
                              )
                            ],
                          ))),
                  Text(
                    formatFixed(balance, asset.decimals,
                        fractionalDigits: 4, trimZeros: false),
                    style: kPageTitleTextStyle.copyWith(color: Colors.white),
                  )
                ],
              ),
              if (actionLabel != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      onPressed: action,
                      label: actionLabel!,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}
