import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/widgets/form/dropdown_field.dart';
import 'package:realunit_wallet/widgets/form/labeled_text_field.dart';

class PhoneNumberField extends StatefulWidget {
  final ValueNotifier<String?> controller;

  const PhoneNumberField({super.key, required this.controller});

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
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
      final value = '$prefix$number';
      widget.controller.value = value;
    }
  }

  bool _isPlausibleNationalNumber(String value) {
    switch (prefix) {
      case '+41':
        return value.length == 9;
      case '+49':
        return value.length >= 10 && value.length <= 11;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Padding(
          padding: const .symmetric(horizontal: 12, vertical: 4),
          child: Text(
            S.of(context).phoneNumber,
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
              flex: 3,
              child: DropdownField<String>(
                initialValue: prefix,
                items: prefixes
                    .map((d) => DropdownMenuItem(value: d, child: Text(d.toString())))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    prefix = v;
                    updatePhoneNumber();
                  }
                },
              ),
            ),
            Expanded(
              flex: 6,
              child: LabeledTextField(
                hintText: '1231234567',
                initialValue: number,
                keyboardType: .phone,
                onChanged: (v) {
                  number = v;
                  updatePhoneNumber();
                },
                hideErrorText: false,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return S.of(context).registerPhoneNumberInvalid;
                  }
                  if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return S.of(context).registerPhoneNumberOnlyDigits;
                  }
                  if (!_isPlausibleNationalNumber(value)) {
                    return S.of(context).registerPhoneNumberInvalidLength;
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
