import 'package:flutter/material.dart';
import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/packages/utils/asset_logo.dart';
import 'package:realunit_wallet/packages/utils/format_fixed.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/hide_amount_text.dart';

class CashHoldingBox extends StatelessWidget {
  final Asset asset;
  final BigInt balance;
  final BigInt? price;
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
    this.price,
    this.backgroundColor = Colors.white,
    this.firstRowTextColor = RealUnitColors.realUnitBlack,
    this.secondRowTextColor = DEuroColors.titanGray60,
    this.showBlockchainIcon = false,
    this.navigateToDetails = true,
    this.leadingSymbol = '€',
    this.trailingSymbol = '',
    this.borderColor,
  });

  TextStyle get _firstRowTextStyle =>
      TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: firstRowTextColor);

  TextStyle get _secondRowTextStyle => TextStyle(fontSize: 12, color: secondRowTextColor);

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
                  Image.asset(getAssetImagePath(asset), width: 32, height: 32),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      HideAmountText(
                        amount: price != null ? balance * price! : balance,
                        decimals: price != null ? 2 : asset.decimals,
                        fractionalDigits: 2,
                        trimZeros: false,
                        style: _firstRowTextStyle,
                        leadingSymbol: leadingSymbol,
                        trailingSymbol: trailingSymbol,
                      ),
                      Text(
                        '$balance × ${formatFixed(price!, 2, fractionalDigits: 2, trimZeros: false)} $trailingSymbol',
                        style: _secondRowTextStyle,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
