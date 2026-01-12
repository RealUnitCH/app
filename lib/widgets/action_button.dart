import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/styles.dart';

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.textStyle = kActionButtonTextStyle,
    this.backgroundColor = RealUnitColors.realUnitBlue,
  });

  final Widget icon;
  final bool isLoading;
  final String label;
  final VoidCallback? onPressed;
  final TextStyle? textStyle;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: backgroundColor,
        ),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          child: SizedBox(
            width: 110,
            height: 50,
            child: isLoading
                ? const CupertinoActivityIndicator(color: DEuroColors.dEuroGold)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [icon, Text(label, textAlign: TextAlign.center, style: textStyle)],
                  ),
          ),
        ),
      );
}
