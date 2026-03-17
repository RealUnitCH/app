import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:realunit_wallet/packages/utils/device_info.dart';

class DatePicker {
  /// Opens a DatePicker depending on the platform
  static Future<DateTime?> pickDate({
    required BuildContext context,
    required DateTime currentDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    if (DeviceInfo.instance.isIOS) {
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

  // copied from https://api.flutter.dev/flutter/cupertino/CupertinoDatePicker-class.html
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
