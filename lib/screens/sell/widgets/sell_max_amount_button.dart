import 'package:flutter/material.dart';
import 'package:realunit_wallet/styles/colors.dart';

class SellMaxAmountButton extends StatelessWidget {
  final VoidCallback onTap;

  const SellMaxAmountButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const .symmetric(horizontal: 8.0),
      child: InkWell(
        borderRadius: .circular(8.0),
        onTap: onTap,
        child: Ink(
          color: RealUnitColors.neutral50,
          child: Container(
            padding: const .all(6.0),
            decoration: BoxDecoration(
              border: Border.all(color: RealUnitColors.neutral300, width: 1),
              borderRadius: .circular(8),
            ),
            child: Text(
              'MAX',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: RealUnitColors.darkBlue,
                fontWeight: .bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
