import 'package:flutter/material.dart';
import 'package:realunit_wallet/styles/colors.dart';

class NumberPad extends StatelessWidget {
  final VoidCallback? onDecimalPressed;
  final VoidCallback onDeletePressed;
  final void Function(int digit) onNumberPressed;

  /// Optional biometric shortcut rendered in the otherwise-empty bottom-left
  /// slot (only when no decimal key is used). Stays tappable even when
  /// [inputEnabled] is false, so a locked-out user can still fall back to
  /// biometrics.
  final VoidCallback? onBiometricPressed;
  final Widget? biometricIcon;

  /// Gates the digit / zero / delete / decimal keys. When false those keys are
  /// inert (no ripple, no callback) while the biometric shortcut keeps working.
  final bool inputEnabled;

  const NumberPad({
    super.key,
    required this.onNumberPressed,
    required this.onDeletePressed,
    this.onDecimalPressed,
    this.onBiometricPressed,
    this.biometricIcon,
    this.inputEnabled = true,
  });

  static const _buttonStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: RealUnitColors.realUnitBlack,
  );

  static const _digits = [1, 2, 3, 4, 5, 6, 7, 8, 9];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Digits 1-9 buttons
            ...List.generate(3, (rowIndex) {
              final rowDigits = _digits.skip(rowIndex * 3).take(3).toList();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: rowDigits.map((digit) {
                    return _buildButton(
                      onTap: inputEnabled ? () => onNumberPressed(digit) : null,
                      child: Text('$digit', style: _buttonStyle),
                    );
                  }).toList(),
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Bottom-left slot: decimal key when requested, otherwise the
                  // optional biometric shortcut, otherwise an empty spacer.
                  _buildButton(
                    onTap: onDecimalPressed != null
                        ? (inputEnabled ? onDecimalPressed : null)
                        : onBiometricPressed,
                    child: _bottomLeftChild(),
                  ),
                  // Zero button
                  _buildButton(
                    onTap: inputEnabled ? () => onNumberPressed(0) : null,
                    child: const Text('0', style: _buttonStyle),
                  ),
                  // Delete Button
                  _buildButton(
                    onTap: inputEnabled ? onDeletePressed : null,
                    child: const Icon(
                      size: 16,
                      fontWeight: FontWeight.bold,
                      Icons.arrow_back_ios_new,
                      color: RealUnitColors.realUnitBlack,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomLeftChild() {
    if (onDecimalPressed != null) return const Text('.', style: _buttonStyle);
    if (onBiometricPressed != null && biometricIcon != null) return biometricIcon!;
    return const SizedBox(width: 60, height: 60);
  }

  Widget _buildButton({
    required Widget child,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(32),
      onTap: onTap,
      child: SizedBox(
        width: 60,
        height: 60,
        child: Center(child: child),
      ),
    );
  }
}
