/// Validator for user-supplied name and address fields that mirror the
/// SIX SIG IG QR-Bill v2.3 permitted character set — printable ASCII plus
/// the Latin diacritics required for the four Swiss national languages.
///
/// Kept byte-for-byte aligned with the API-side
/// `Config.formats.swissPaymentText` regex
/// (`api/src/config/config.ts`) so client-side validation matches what the
/// backend's `@IsSwissPaymentText()` decorator accepts. Without this,
/// non-Latin input would only fail server-side with a generic 400.
library;

final RegExp _swissPaymentText = RegExp(
  r'^[\x20-\x7E'
  'ÀÁÂÄÇÈÉÊË'
  'ÌÍÎÏÑÒÓÔÖ'
  'ÙÚÛÜÝß'
  'àáâäçèéêë'
  'ìíîïñòóôö'
  'ùúûüý'
  r'\n]*$',
  unicode: true,
);

/// Returns `true` if [value] contains only characters permitted in Swiss
/// payment systems. Empty/null values are considered valid (callers should
/// chain a non-empty check separately).
bool isSwissPaymentText(String? value) {
  if (value == null || value.isEmpty) return true;
  return _swissPaymentText.hasMatch(value);
}
