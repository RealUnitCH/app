import 'package:realunit_wallet/widgets/info_row.dart';
import 'package:flutter/material.dart';

class AmountInfoRow extends StatelessWidget {
  const AmountInfoRow({
    super.key,
    required this.title,
    required this.amountString,
    required this.currencySymbol,
    this.padding,
  });

  final String amountString;
  final String title;
  final String currencySymbol;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => InfoRow(
        leading: title,
        trailing: "$amountString $currencySymbol",
        padding: padding,
      );
}
