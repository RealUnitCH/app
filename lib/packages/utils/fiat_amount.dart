/// Parses user-typed fiat text, accepting a comma as the decimal separator.
/// Rejects grouping-ambiguous input — a lone separator followed by exactly
/// three digits (`1,000` / `1.000`) usually means a thousands group, and
/// reading it as a decimal would quote 1/1000th of the intended amount.
double? tryParseFiatAmount(String input) {
  if (RegExp(r'^\d+[.,]\d{3}$').hasMatch(input)) return null;
  return double.tryParse(input.replaceAll(',', '.'));
}

/// The whole-currency integer the backend charges for the raw [input] the user
/// typed (e.g. `300,75` → `301`); empty input counts as zero.
int chargedFiatAmount(String input) {
  final amount = tryParseFiatAmount(input.isEmpty ? '0' : input);
  if (amount == null) throw FormatException('Invalid fiat amount', input);
  return amount.round();
}
