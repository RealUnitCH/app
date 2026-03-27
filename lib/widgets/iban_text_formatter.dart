class IbanTextFormatter {
  static String formatIban(String iban) {
    final raw = iban.replaceAll(' ', '').toUpperCase();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(raw[i]);
    }
    return buffer.toString();
  }
}
