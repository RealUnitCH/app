import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DatePicker {
  static Future<DateTime?> pickDate({
    required BuildContext context,
    required DateTime currentDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _showCupertinoPicker(
        context: context,
        initialDate: currentDate,
        firstDate: firstDate,
        lastDate: lastDate,
      );
    }

    return showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }

  static Future<DateTime?> _showCupertinoPicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    DateTime selectedDate = initialDate;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: CupertinoDatePicker(
            initialDateTime: initialDate,
            minimumDate: firstDate,
            maximumDate: lastDate,
            mode: CupertinoDatePickerMode.date,
            onDateTimeChanged: (date) {
              selectedDate = date;
            },
          ),
        ),
      ),
    );

    return selectedDate;
  }
}
