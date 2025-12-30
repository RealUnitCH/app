import 'package:flutter/material.dart';
import 'package:realunit_wallet/styles/colors.dart';

class RegistrationTextField extends StatelessWidget {
  final String? label;
  final String? initialValue;
  final TextEditingController? controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;
  final bool hideErrorText;

  const RegistrationTextField({
    super.key,
    this.label,
    this.initialValue,
    this.controller,
    this.hintText,
    this.keyboardType,
    this.onChanged,
    this.validator,
    this.hideErrorText = true,
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
                fontSize: 13,
                fontWeight: FontWeight.bold,
                height: 18 / 13,
              ),
            ),
          ),
        TextFormField(
          initialValue: initialValue,
          onChanged: onChanged,
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              borderSide: BorderSide(color: RealUnitColors.neutral300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              borderSide: BorderSide(color: RealUnitColors.realUnitBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              borderSide: BorderSide(color: RealUnitColors.status.red600),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              borderSide: BorderSide(color: RealUnitColors.status.red600, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            hintStyle: TextStyle(color: RealUnitColors.neutral400),
            errorStyle: hideErrorText
                ? TextStyle(
                    height: -1,
                    fontSize: 0,
                  )
                : null,
          ),
          keyboardType: keyboardType,
          validator: validator,
        ),
      ],
    );
  }
}
