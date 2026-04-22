import 'package:flutter/material.dart';

/// Should be used instead of [OutlinedButton] to ensure consistent styling across the app.
class AppOutlinedButton extends StatelessWidget {
  const AppOutlinedButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final button = icon != null
        ? OutlinedButton.icon(onPressed: onPressed, icon: icon!, label: Text(label))
        : OutlinedButton(onPressed: onPressed, child: Text(label));
    if (fullWidth) return SizedBox(width: double.infinity, child: button);
    return button;
  }
}
