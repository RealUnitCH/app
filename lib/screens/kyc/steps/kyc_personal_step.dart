import 'package:flutter/material.dart';
import 'package:realunit_wallet/screens/kyc/widgets/kyc_dropdown_field.dart';
import 'package:realunit_wallet/screens/kyc/widgets/kyc_text_field.dart';

class KycPersonalStep extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController firstnameCtrl;
  final TextEditingController surnameCtrl;
  final TextEditingController phoneCtrl;
  final void Function(String birthdate) onBirthdaySelected;
  final VoidCallback onNext;

  KycPersonalStep({
    super.key,
    required this.emailCtrl,
    required this.firstnameCtrl,
    required this.surnameCtrl,
    required this.phoneCtrl,
    required this.onBirthdaySelected,
    required this.onNext,
  });

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Form(
        key: _formKey,
        child: Column(
          spacing: 16,
          children: [
            KycTextField(
              label: 'E-Mail',
              hintText: 'E-Mail',
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) return "E-Mail ist erforderlich";
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return "E-Mail ist ungültig";
                return null;
              },
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Expanded(
                  child: KycTextField(
                    label: 'Vorname',
                    hintText: 'Max',
                    controller: firstnameCtrl,
                    keyboardType: TextInputType.name,
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Erforderlich";
                      return null;
                    },
                  ),
                ),
                Expanded(
                  child: KycTextField(
                    label: 'Nachname',
                    hintText: 'Mustermann',
                    controller: surnameCtrl,
                    keyboardType: TextInputType.name,
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Erforderlich";
                      return null;
                    },
                  ),
                ),
              ],
            ),
            BirthdayField(
              onChanged: onBirthdaySelected,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(
                    'Telefonnummer',
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
                      flex: 3,
                      child: KycDropdownField<String>(
                        initialValue: '+41',
                        hintText: '',
                        items: ['+41', '+49'],
                        onChanged: (v) {},
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: KycTextField(
                        hintText: '1231234567',
                        keyboardType: TextInputType.phone,
                        controller: phoneCtrl,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Telefonnummer ist erforderlich";
                          }
                          if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                            return "Nur Zahlen sind erlaubt";
                          }
                          if (value.length < 6) {
                            return "Telefonnummer ist zu kurz";
                          }
                          return null;
                        },
                      ),
                    )
                  ],
                ),
              ],
            ),
            FilledButton(
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  onNext();
                }
              },
              child: const Text("Weiter"),
            ),
          ],
        ),
      ),
    );
  }
}

class BirthdayField extends StatefulWidget {
  final void Function(String value) onChanged;

  const BirthdayField({super.key, required this.onChanged});

  @override
  State<BirthdayField> createState() => _BirthdayFieldState();
}

class _BirthdayFieldState extends State<BirthdayField> {
  String? selectedDay;
  String? selectedMonth;
  String? selectedYear;

  List<String> days = List.generate(31, (i) => "${i + 1}".padLeft(2, '0'));
  List<String> months = List.generate(12, (i) => "${i + 1}".padLeft(2, '0'));
  List<String> years = List.generate(
    120,
    (i) => "${DateTime.now().year - i}",
  );

  void updateBirthday() {
    if (selectedDay != null && selectedMonth != null && selectedYear != null) {
      final value = "${selectedYear!}-${selectedMonth!}-${selectedDay!}"; // YYYY-MM-DD
      widget.onChanged(value);
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
            'Geburtstag',
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
              flex: 3,
              child: KycDropdownField<String>(
                hintText: 'Tag',
                items: days,
                onChanged: (v) {
                  setState(() => selectedDay = v);
                  updateBirthday();
                },
                validator: (v) => v == null ? "Erforderlich" : null,
              ),
            ),
            Expanded(
              flex: 3,
              child: KycDropdownField<String>(
                hintText: 'Monat',
                items: months,
                onChanged: (v) {
                  setState(() => selectedMonth = v);
                  updateBirthday();
                },
                validator: (v) => v == null ? "Erforderlich" : null,
              ),
            ),
            Expanded(
              flex: 3,
              child: KycDropdownField<String>(
                hintText: 'Jahr',
                items: years,
                onChanged: (v) {
                  setState(() => selectedYear = v);
                  updateBirthday();
                },
                validator: (v) => v == null ? "Erforderlich" : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
