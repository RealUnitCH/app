import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:realunit_wallet/styles/colors.dart';

class SettingsTaxReportDatePicker extends StatelessWidget {
  final DateTime? initialDate;
  final void Function()? onPressed;

  const SettingsTaxReportDatePicker({
    super.key,
    this.initialDate,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(color: RealUnitColors.neutral300),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat('dd.MM.yyyy').format(initialDate ?? DateTime.now())),
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                    color: RealUnitColors.neutral400,
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
