import 'package:flutter/material.dart';
import 'package:realunit_wallet/styles/styles.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => ElevatedButton(
        onPressed: onPressed,
        style: kFullwidthGrayButtonStyle,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: kPrimaryButtonTextStyle,
        ),
      );
}
