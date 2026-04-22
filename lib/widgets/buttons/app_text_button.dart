import 'package:flutter/material.dart';

/// Should be used instead of [TextButton] to ensure consistent styling across the app.
class AppTextButton extends StatelessWidget {
  const AppTextButton({
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
        ? TextButton.icon(onPressed: onPressed, icon: icon!, label: Text(label))
        : TextButton(onPressed: onPressed, child: Text(label));
    if (fullWidth) return SizedBox(width: double.infinity, child: button);
    return button;
  }
}
