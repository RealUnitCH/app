import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/kyc/widgets/kyc_dropdown_field.dart';

class KycBirthdayField extends StatefulWidget {
  final ValueNotifier<String?> controller;

  const KycBirthdayField({
    super.key,
    required this.controller,
  });

  @override
  State<KycBirthdayField> createState() => _KycBirthdayFieldState();
}

class _KycBirthdayFieldState extends State<KycBirthdayField> {
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
      selectedYear = parts[0];
      selectedMonth = parts[1];
      selectedDay = parts[2];
    }
  }

  void updateBirthday() {
    if (selectedDay != null && selectedMonth != null && selectedYear != null) {
      final value = '$selectedYear-$selectedMonth-$selectedDay';
      widget.controller.value = value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(
            S.of(context).birthday,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              height: 18 / 13,
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Expanded(
              flex: 1,
              child: KycDropdownField<String>(
                hintText: S.of(context).day,
                items: days
                    .map((d) => DropdownMenuItem(value: d, child: Text(d.toString())))
                    .toList(),
                initialValue: selectedDay,
                onChanged: (v) {
                  setState(() => selectedDay = v);
                  updateBirthday();
                },
                validator: (v) => v == null ? '' : null,
              ),
            ),
            Expanded(
              flex: 1,
              child: KycDropdownField<String>(
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
              child: KycDropdownField<String>(
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
