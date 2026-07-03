import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/widgets/form/dropdown_field.dart';

class BirthdayField extends StatefulWidget {
  final ValueNotifier<String?> controller;

  const BirthdayField({
    super.key,
    required this.controller,
  });

  @override
  State<BirthdayField> createState() => _BirthdayFieldState();
}

class _BirthdayFieldState extends State<BirthdayField> {
  String? selectedDay;
  String? selectedMonth;
  String? selectedYear;

  List<String> days = List.generate(31, (i) => '${i + 1}'.padLeft(2, '0'));
  List<String> months = List.generate(12, (i) => '${i + 1}'.padLeft(2, '0'));
  List<String> years = List.generate(82, (i) => '${DateTime.now().year - i - 18}');

  @override
  void initState() {
    super.initState();
    final value = widget.controller.value;
    if (value != null) {
      final parts = value.split('-');
      if (parts.length == 3) {
        // Only seed values the dropdowns actually offer; a value outside the
        // item list trips DropdownButtonFormField's single-match assert.
        if (years.contains(parts[0])) selectedYear = parts[0];
        if (months.contains(parts[1])) selectedMonth = parts[1];
        if (days.contains(parts[2])) selectedDay = parts[2];
      }
    }
  }

  void updateBirthday() {
    if (selectedDay != null && selectedMonth != null && selectedYear != null) {
      final value = '$selectedYear-$selectedMonth-$selectedDay';
      widget.controller.value = value;
    }
  }

  // False for impossible combinations like 31.02.: DateTime rolls the
  // overflow into the next month.
  bool get isValidCalendarDate {
    if (selectedDay == null || selectedMonth == null || selectedYear == null) return true;
    final date = DateTime(
      int.parse(selectedYear!),
      int.parse(selectedMonth!),
      int.parse(selectedDay!),
    );
    return date.month == int.parse(selectedMonth!);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Padding(
          padding: const .symmetric(horizontal: 12, vertical: 4),
          child: Text(
            S.of(context).birthday,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: .bold,
              height: 18 / 13,
            ),
          ),
        ),
        Row(
          crossAxisAlignment: .start,
          spacing: 10,
          children: [
            Expanded(
              flex: 1,
              child: DropdownField<String>(
                hintText: S.of(context).day,
                items: days
                    .map((d) => DropdownMenuItem(value: d, child: Text(d.toString())))
                    .toList(),
                initialValue: selectedDay,
                onChanged: (v) {
                  setState(() => selectedDay = v);
                  updateBirthday();
                },
                validator: (v) => v == null || !isValidCalendarDate ? '' : null,
              ),
            ),
            Expanded(
              flex: 1,
              child: DropdownField<String>(
                hintText: S.of(context).month,
                items: months
                    .map((m) => DropdownMenuItem(value: m, child: Text(m.toString())))
                    .toList(),
                initialValue: selectedMonth,
                onChanged: (v) {
                  setState(() => selectedMonth = v);
                  updateBirthday();
                },
                validator: (v) => v == null ? '' : null,
              ),
            ),
            Expanded(
              flex: 1,
              child: DropdownField<String>(
                hintText: S.of(context).year,
                items: years
                    .map((y) => DropdownMenuItem(value: y, child: Text(y.toString())))
                    .toList(),
                initialValue: selectedYear,
                onChanged: (v) {
                  setState(() => selectedYear = v);
                  updateBirthday();
                },
                validator: (v) => v == null ? '' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
