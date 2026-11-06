import 'package:flutter/material.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/styles/colors.dart';

class PayQuoteParts {
  final double billChf;
  final double billRealu;
  final double feeChf;
  final double feeRealu;
  final double roundingChf;
  final double roundingRealu;
  final double totalChf;
  final double totalRealu;

  const PayQuoteParts({
    required this.billChf,
    required this.billRealu,
    required this.feeChf,
    required this.feeRealu,
    required this.roundingChf,
    required this.roundingRealu,
    required this.totalChf,
    required this.totalRealu,
  });
}

/// Splits the sold shares into the bill, the fee, and the whole-share round-up.
/// The round-up is the remainder, so the three REALU lines add up to [shares].
PayQuoteParts payQuoteParts({
  required double billChf,
  required double shares,
  required double proceedsChf,
  required double feeChf,
  required double feeRealu,
}) {
  final price = shares == 0 ? 0.0 : proceedsChf / shares;
  final billRealu = price == 0 ? 0.0 : billChf / price;
  final roundingChf = proceedsChf - billChf - feeChf;
  final roundingRealu = shares - billRealu - feeRealu;
  return PayQuoteParts(
    billChf: billChf,
    billRealu: billRealu,
    feeChf: feeChf,
    feeRealu: feeRealu,
    roundingChf: roundingChf,
    roundingRealu: roundingRealu,
    totalChf: billChf + feeChf + roundingChf,
    totalRealu: billRealu + feeRealu + roundingRealu,
  );
}

String formatPayFiat(double amount, String asset) => '${amount.toStringAsFixed(2)} $asset';

String formatWholeRealu(double shares) => '${shares.toStringAsFixed(0)} ${realUnitAsset.symbol}';

/// At least two decimals, up to eight, without a tail of zeros.
String formatPayRealu(double amount) {
  final rounded = (amount * 1e8).round() / 1e8;
  var text = rounded.toStringAsFixed(8);
  text = text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  if (!text.contains('.')) {
    text = '$text.00';
  } else if (text.split('.').last.length == 1) {
    text = '${text}0';
  }
  return '$text ${realUnitAsset.symbol}';
}

class PayQuoteReceiptCard extends StatelessWidget {
  final List<Widget> children;

  const PayQuoteReceiptCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) {
        rows.add(
          const Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: RealUnitColors.neutral200,
          ),
        );
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: RealUnitColors.neutral50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: rows),
    );
  }
}

class PayQuoteAmountRow extends StatelessWidget {
  final String label;
  final String realu;
  final String chf;
  final String? also;

  const PayQuoteAmountRow({
    super.key,
    required this.label,
    required this.realu,
    required this.chf,
    this.also,
  });

  @override
  Widget build(BuildContext context) {
    final small = Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35);
    final fiatStyle = small?.copyWith(color: RealUnitColors.neutral600);
    final Widget fiat = also == null
        ? Text(chf, textAlign: TextAlign.end, softWrap: true, style: fiatStyle)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(chf, textAlign: TextAlign.end, softWrap: true, style: fiatStyle),
              Text(also!, textAlign: TextAlign.end, softWrap: true, style: fiatStyle),
            ],
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 4,
        children: [
          Text(
            label,
            softWrap: true,
            style: small?.copyWith(color: RealUnitColors.neutral500),
          ),
          Row(
            spacing: 12,
            children: [
              Flexible(
                child: Text(
                  realu,
                  softWrap: true,
                  style: small?.copyWith(
                    color: RealUnitColors.realUnitBlack,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Flexible(child: fiat),
            ],
          ),
        ],
      ),
    );
  }
}
