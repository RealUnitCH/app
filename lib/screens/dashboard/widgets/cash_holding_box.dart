import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/packages/utils/asset_logo.dart';
import 'package:realunit_wallet/packages/utils/format_fixed.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/hide_amount_text.dart';

class CashHoldingBox extends StatelessWidget {
  final Asset asset;
  final BigInt balance;
  final BigInt? price;
  final String leadingSymbol;
  final String trailingSymbol;

  const CashHoldingBox({
    super.key,
    required this.asset,
    required this.balance,
    this.price,
    this.leadingSymbol = '€',
    this.trailingSymbol = '',
  });

  @override
  Widget build(BuildContext context) => InkWell(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            color: RealUnitColors.basic.white,
          ),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 12.0,
                children: [
                  Image.asset(getAssetImagePath(asset), width: 32, height: 32),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.symbol,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 20 / 16,
                          ),
                        ),
                        Text(
                          S.of(context).realunitStockToken,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 16 / 12,
                            color: RealUnitColors.neutral500,
                          ),
                        ),
                      ],
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 20 / 16,
                        ),
                        leadingSymbol: leadingSymbol,
                        trailingSymbol: trailingSymbol,
                      ),
                      Text(
                        '$balance × ${formatFixed(price!, 2, fractionalDigits: 2, trimZeros: false)} $trailingSymbol',
                        style: const TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          color: RealUnitColors.neutral500,
                        ),
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
