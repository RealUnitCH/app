import 'package:flutter/material.dart';
import 'package:realunit_wallet/screens/registration/widgets/registration_dropdown_field.dart';
import 'package:realunit_wallet/screens/registration/widgets/registration_text_field.dart';

class RegistrationPhoneNumberField extends StatefulWidget {
  final ValueNotifier<String?> controller;

  const RegistrationPhoneNumberField({super.key, required this.controller});

  @override
  State<RegistrationPhoneNumberField> createState() => _RegistrationPhoneNumberFieldState();
}

class _RegistrationPhoneNumberFieldState extends State<RegistrationPhoneNumberField> {
  final prefixes = ['+41', '+49'];
  String? prefix;
  String? number;

  @override
  void initState() {
    super.initState();
    final value = widget.controller.value;
    if (value != null) {
      for (var p in prefixes) {
        if (value.startsWith(p)) {
          prefix = p;
          number = value.substring(p.length);
          break;
        }
      }
    } else {
      prefix = prefixes.first;
    }
  }

  void updatePhoneNumber() {
    if (prefix != null && number != null) {
      final value = "$prefix$number";
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
              child: RegistrationDropdownField<String>(
                  initialValue: prefix,
                  items: prefixes
                      .map((d) => DropdownMenuItem(value: d, child: Text(d.toString())))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      prefix = v;
                      updatePhoneNumber();
                    }
                  }),
            ),
            Expanded(
              flex: 6,
              child: RegistrationTextField(
                hintText: '1231234567',
                initialValue: number,
                keyboardType: TextInputType.phone,
                onChanged: (v) {
                  number = v;
                  updatePhoneNumber();
                },
                hideErrorText: false,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Nummer ist erforderlich";
                  }
                  if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return "Nur Zahlen sind erlaubt";
                  }
                  if (value.length < 6) {
                    return "Nummer ist zu kurz";
                  }
                  return null;
                },
              ),
            )
          ],
        ),
      ],
    );
  }
}
