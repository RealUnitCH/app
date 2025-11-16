import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/styles.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  final bool isLoading;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: kFullwidthPrimaryButtonStyle,
        child: isLoading
            ? CupertinoActivityIndicator(
                color: DEuroColors.dEuroGold,
              )
            : Text(
                label,
                textAlign: TextAlign.center,
                style: kPrimaryButtonTextStyle,
              ),
      );
}
