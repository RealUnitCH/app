import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/date_picker.dart';

class DatePickerField extends StatelessWidget {
  final DateTime initialDate;
  final String? label;
  final DateTime firstDate;
  final DateTime lastDate;
  final void Function(DateTime)? onDateSelected;

  const DatePickerField({
    super.key,
    this.label,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              label!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 16 / 12,
                color: RealUnitColors.neutral500,
              ),
            ),
          ),
        GestureDetector(
          onTap: () => _pickDate(context),
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
                  Text(DateFormat('dd.MM.yyyy').format(initialDate)),
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

  Future<void> _pickDate(BuildContext context) async {
    final pickedDate = await DatePicker.pickDate(
      context: context,
      currentDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (pickedDate == null || !context.mounted) return;
    onDateSelected?.call(pickedDate);
  }
}
