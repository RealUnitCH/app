import 'package:flutter/material.dart';
import 'package:realunit_wallet/styles/colors.dart';

class KycDropdownField<T> extends StatelessWidget {
  final String? label;
  final T? initialValue;
  final String? hintText;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;

  const KycDropdownField({
    super.key,
    this.label,
    this.initialValue,
    this.hintText,
    required this.items,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 4.0,
            ),
            child: Text(
              label!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                height: 18 / 13,
              ),
            ),
          ),
        ButtonTheme(
          alignedDropdown: true,
          child: DropdownButtonFormField<T>(
            isExpanded: true,
            initialValue: initialValue,
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
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 14.0,
              ),
            ),
            items: items,
            onChanged: onChanged,
            validator: validator,
          ),
        ),
      ],
    );
  }
}
