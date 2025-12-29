import 'package:flutter/material.dart';
import 'package:realunit_wallet/styles/colors.dart';

class KycTextField extends StatelessWidget {
  final String? label;
  final TextEditingController? controller;
  final String hintText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final String? initialValue;

  const KycTextField({
    super.key,
    this.label,
    this.controller,
    required this.hintText,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.initialValue,
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
              borderSide: BorderSide(color: RealUnitColors.neutral300), // normal border
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              borderSide:
                  BorderSide(color: RealUnitColors.realUnitBlue, width: 2), // focused border
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              borderSide: BorderSide(color: RealUnitColors.status.red600), // error border
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              borderSide:
                  BorderSide(color: RealUnitColors.status.red600, width: 2), // focused + error
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            hintStyle: TextStyle(color: RealUnitColors.neutral400),
          ),
          keyboardType: keyboardType,
          validator: validator,
        ),
      ],
    );
  }
}
