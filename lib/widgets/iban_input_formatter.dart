import 'package:flutter/services.dart';

class IbanInputFormatter extends TextInputFormatter {
  static final _validChars = RegExp(r'[A-Z0-9]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove spaces and uppercase
    final raw = newValue.text.replaceAll(' ', '').toUpperCase();

    // Filter invalid characters
    final filtered = raw.split('').where((c) => _validChars.hasMatch(c)).join();

    final buffer = StringBuffer();
    for (var i = 0; i < filtered.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(filtered[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
      composing: TextRange.empty,
    );
  }
}
