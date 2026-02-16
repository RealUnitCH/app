import 'package:flutter/material.dart';
import 'package:realunit_wallet/styles/colors.dart';

class TimePeriodButton extends StatelessWidget {
  final String label;
  final void Function()? onTap;
  final bool isSelected;

  const TimePeriodButton(
    this.label, {
    super.key,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? RealUnitColors.realUnitBlue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? RealUnitColors.realUnitBlue : RealUnitColors.neutral400,
            height: 18 / 14,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
