import 'package:flutter/material.dart';
import 'package:realunit_wallet/styles/colors.dart';

class RegistrationDropdownField<T> extends StatelessWidget {
  final String? label;
  final T? initialValue;
  final String? hintText;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final List<DropdownMenuItem<T>> items;

  const RegistrationDropdownField({
    super.key,
    this.label,
    this.initialValue,
    this.hintText,
    this.onChanged,
    this.validator,
    required this.items,
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
            initialValue: initialValue,
            validator: validator,
            onChanged: onChanged,
            items: items,
            isExpanded: true,
            isDense: true,
            menuMaxHeight: MediaQuery.sizeOf(context).height * 0.4,
            decoration: InputDecoration(
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
              hintStyle: TextStyle(color: RealUnitColors.neutral400),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 14.0,
              ),
            ),
            hint: hintText != null
                ? Text(
                    hintText!,
                    style: TextStyle(
                      color: RealUnitColors.neutral400,
                    ),
                  )
                : null,
            icon: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.arrow_drop_down),
            ),
          ),
        ),
      ],
    );
  }
}
