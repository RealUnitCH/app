import 'package:realunit_wallet/styles/colors.dart';
import 'package:flutter/material.dart';

class PinIndicator extends StatelessWidget {
  final int expectedPinLength;
  final int pinLength;
  final bool wrongPin;

  static const _size = 10.0;

  const PinIndicator({
    super.key,
    required this.pinLength,
    required this.expectedPinLength,
    required this.wrongPin,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 180,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(expectedPinLength, (index) {
            final isFilled = pinLength > index;

            return Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: wrongPin ? Colors.red : DEuroColors.anthracite),
                color: isFilled ? DEuroColors.anthracite : Colors.transparent,
              ),
            );
          }),
        ),
      );
}
