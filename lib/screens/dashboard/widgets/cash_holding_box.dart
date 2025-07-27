import 'package:deuro_wallet/models/asset.dart';
import 'package:deuro_wallet/styles/colors.dart';
import 'package:deuro_wallet/widgets/chain_asset_icon.dart';
import 'package:deuro_wallet/widgets/hide_amount_text.dart';
import 'package:flutter/material.dart';

class CashHoldingBox extends StatelessWidget {
  final Asset asset;
  final BigInt balance;
  final Color backgroundColor;
  final Color? borderColor;
  final Color firstRowTextColor;
  final Color secondRowTextColor;
  final bool showBlockchainIcon;
  final bool navigateToDetails;
  final String leadingSymbol;
  final String trailingSymbol;

  const CashHoldingBox({
    super.key,
    required this.asset,
    required this.balance,
    this.backgroundColor = Colors.white,
    this.firstRowTextColor = DEuroColors.anthracite,
    this.secondRowTextColor = DEuroColors.titanGray60,
    this.showBlockchainIcon = false,
    this.navigateToDetails = true,
    this.leadingSymbol = "€",
    this.trailingSymbol = "",
    this.borderColor,
  });

  TextStyle get _firstRowTextStyle => TextStyle(
      fontSize: 14, fontWeight: FontWeight.w700, color: firstRowTextColor);

  TextStyle get _secondRowTextStyle =>
      TextStyle(fontSize: 12, color: secondRowTextColor);

  @override
  Widget build(BuildContext context) => InkWell(
        child: Container(
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: borderColor != null ? Border.all(color: borderColor!, width: 3) : null,
            color: backgroundColor,
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ChainAssetIcon(asset: asset),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(asset.symbol, style: _firstRowTextStyle),
                          Text(asset.name, style: _secondRowTextStyle)
                        ],
                      ),
                    ),
                  ),
                  HideAmountText(
                    amount: balance, decimals: asset.decimals, fractionalDigits: 4, trimZeros: false,
                    style: _firstRowTextStyle,
                    leadingSymbol: leadingSymbol,
                    trailingSymbol: trailingSymbol,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
