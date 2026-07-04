/// Parses user-typed fiat text, accepting a comma as the decimal separator.
double? tryParseFiatAmount(String input) => double.tryParse(input.replaceAll(',', '.'));

/// The whole-currency integer the backend charges for the raw [input] the user
/// typed (e.g. `300,75` → `301`); empty input counts as zero.
int chargedFiatAmount(String input) {
  final amount = tryParseFiatAmount(input.isEmpty ? '0' : input);
  if (amount == null) throw FormatException('Invalid fiat amount', input);
  return amount.round();
}
