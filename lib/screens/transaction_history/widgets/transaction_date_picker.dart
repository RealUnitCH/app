import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:realunit_wallet/styles/colors.dart';

class TransactionDatePicker extends StatelessWidget {
  final DateTime? initialDate;
  final String label;
  final void Function()? onPressed;

  const TransactionDatePicker({
    super.key,
    required this.label,
    this.initialDate,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 16 / 12,
              color: RealUnitColors.neutral500,
            ),
          ),
        ),
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
