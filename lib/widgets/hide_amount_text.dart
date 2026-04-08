import 'package:flutter/material.dart';
import 'package:realunit_wallet/packages/utils/format_fixed.dart';

class HideAmountText extends StatelessWidget {
  const HideAmountText({
    super.key,
    this.style,
    required this.amount,
    this.decimals = 18,
    this.fractionalDigits = 2,
    this.trimZeros = false,
    this.leadingSymbol = '€',
    this.trailingSymbol = '',
    this.textAlign,
  });

  final String leadingSymbol;
  final String trailingSymbol;
  final TextStyle? style;
  final BigInt amount;
  final int decimals;
  final int fractionalDigits;
  final bool trimZeros;
  final TextAlign? textAlign;

  String _formatAmount() {
    if (amount == BigInt.zero) {
      return '--.--';
    }
    return formatFixed(amount, decimals, fractionalDigits: fractionalDigits, trimZeros: trimZeros);
  }

  @override
  Widget build(BuildContext context) => Text(
    "${leadingSymbol.isNotEmpty ? "$leadingSymbol " : ""}${_formatAmount()} $trailingSymbol",
    style: style,
    textAlign: textAlign,
  );
}
