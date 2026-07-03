/// Transliteration helpers for fields that go into BitBox02 EIP-712 sign
/// requests. The BitBox firmware rejects any non-ASCII byte in a `string`
/// field with `ErrInvalidInput` (code 101), so name/address/city values
/// containing German umlauts or other UTF-8 characters cause "Registration
/// failed" without a useful error. Production-observed 2026-05-15 with
/// `name="Joshua Krüger"` (13 chars, 14 UTF-8 bytes).
///
/// We transliterate in BOTH directions of the registration ceremony — the
/// backend KYC payload AND the EIP-712 signed data — so the two stay
/// byte-identical and the signature verifies. Anyone needing the user's
/// legal name with diacritics should keep it on a separate field outside
/// the BitBox sign envelope.
library;

import 'package:characters/characters.dart';

/// Multi-char replacements (German digraphs + nordic æ/ø + ellipsis) —
/// applied first.
const Map<String, String> _multiCharReplacements = {
  // German
  'ä': 'ae', 'ö': 'oe', 'ü': 'ue', 'ß': 'ss',
  'Ä': 'Ae', 'Ö': 'Oe', 'Ü': 'Ue', 'ẞ': 'SS',
  // Nordic
  'æ': 'ae', 'Æ': 'Ae',
  'œ': 'oe', 'Œ': 'Oe',
  'ø': 'oe', 'Ø': 'Oe',
  'ð': 'd', 'Ð': 'D',
  'þ': 'th', 'Þ': 'Th',
  // Typographic punctuation produced by iOS/Android autocorrect — without
  // this, names like `D’Angelo` end up signed as `D?Angelo` and the
  // BitBox-side payload no longer matches the backend's.
  '…': '...',
};

/// Single-char replacements — base-letter equivalents for any single
/// Latin-script grapheme. Keep alphabetical to make merges/audits easy.
const Map<String, String> _singleCharReplacements = {
  // a
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'å': 'a', 'ā': 'a', 'ă': 'a', 'ą': 'a',
  'À': 'A', 'Á': 'A', 'Â': 'A', 'Ã': 'A', 'Å': 'A', 'Ā': 'A', 'Ă': 'A', 'Ą': 'A',
  // c
  'ç': 'c', 'ć': 'c', 'č': 'c', 'ĉ': 'c', 'ċ': 'c',
  'Ç': 'C', 'Ć': 'C', 'Č': 'C', 'Ĉ': 'C', 'Ċ': 'C',
  // d
  'ď': 'd', 'đ': 'd',
  'Ď': 'D', 'Đ': 'D',
  // e
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ė': 'e', 'ę': 'e', 'ě': 'e',
  'È': 'E', 'É': 'E', 'Ê': 'E', 'Ë': 'E', 'Ē': 'E', 'Ė': 'E', 'Ę': 'E', 'Ě': 'E',
  // g
  'ğ': 'g', 'ġ': 'g',
  'Ğ': 'G', 'Ġ': 'G',
  // h
  'ħ': 'h', 'Ħ': 'H',
  // i
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i', 'į': 'i', 'ı': 'i',
  'Ì': 'I', 'Í': 'I', 'Î': 'I', 'Ï': 'I', 'Ī': 'I', 'Į': 'I', 'İ': 'I',
  // j
  'ĵ': 'j', 'Ĵ': 'J',
  // k
  'ķ': 'k', 'Ķ': 'K',
  // l
  'ł': 'l', 'ľ': 'l', 'ĺ': 'l', 'ļ': 'l',
  'Ł': 'L', 'Ľ': 'L', 'Ĺ': 'L', 'Ļ': 'L',
  // n
  'ñ': 'n', 'ń': 'n', 'ň': 'n', 'ņ': 'n',
  'Ñ': 'N', 'Ń': 'N', 'Ň': 'N', 'Ņ': 'N',
  // o
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ō': 'o', 'ő': 'o',
  'Ò': 'O', 'Ó': 'O', 'Ô': 'O', 'Õ': 'O', 'Ō': 'O', 'Ő': 'O',
  // r
  'ŕ': 'r', 'ř': 'r', 'ŗ': 'r',
  'Ŕ': 'R', 'Ř': 'R', 'Ŗ': 'R',
  // s
  'ś': 's', 'š': 's', 'ş': 's', 'ŝ': 's', 'ș': 's',
  'Ś': 'S', 'Š': 'S', 'Ş': 'S', 'Ŝ': 'S', 'Ș': 'S',
  // t
  'ť': 't', 'ţ': 't', 'ț': 't', 'ŧ': 't',
  'Ť': 'T', 'Ţ': 'T', 'Ț': 'T', 'Ŧ': 'T',
  // u
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ū': 'u', 'ů': 'u', 'ű': 'u', 'ų': 'u',
  'Ù': 'U', 'Ú': 'U', 'Û': 'U', 'Ū': 'U', 'Ů': 'U', 'Ű': 'U', 'Ų': 'U',
  // w
  'ŵ': 'w', 'Ŵ': 'W',
  // y
  'ý': 'y', 'ÿ': 'y', 'ŷ': 'y',
  'Ý': 'Y', 'Ÿ': 'Y', 'Ŷ': 'Y',
  // z
  'ź': 'z', 'ż': 'z', 'ž': 'z',
  'Ź': 'Z', 'Ż': 'Z', 'Ž': 'Z',
  // Typographic punctuation (smart quotes + en/em dashes) — folded to
  // the ASCII equivalent the user typed before autocorrect intervened.
  '‘': "'", // ‘ left single quote
  '’': "'", // ’ right single quote / curly apostrophe
  '“': '"', // “ left double quote
  '”': '"', // ” right double quote
  '–': '-', // – en dash
  '—': '-', // — em dash
  // Guillemets — the quotation marks used in Swiss French/Italian text. Without
  // these, an address line like `«Le Château»` was signed as `?Le Château?`
  // (placeholder loss) and the BitBox payload no longer matched the backend's.
  '«': '"', // « left-pointing double angle quote
  '»': '"', // » right-pointing double angle quote
  '‹': "'", // ‹ left-pointing single angle quote
  '›': "'", // › right-pointing single angle quote
};

/// Returns an ASCII-safe representation of [input]. German umlauts and
/// eszett expand to their two-character equivalents (`ä` → `ae`). Any
/// remaining non-ASCII runes are replaced with `?` so the result is
/// guaranteed printable-ASCII and the BitBox firmware accepts it as a
/// `string` typed-data value.
String toBitboxSafeAscii(String input) {
  if (input.runes.every((r) => r >= 0x20 && r < 0x7F)) {
    return input;
  }
  final out = StringBuffer();
  for (final char in input.characters) {
    // Multi-char first (digraph expansions like ä→ae, ß→ss, æ→ae).
    final multi = _multiCharReplacements[char];
    if (multi != null) {
      out.write(multi);
      continue;
    }
    // Single-char base-letter equivalents (é→e, ñ→n, ł→l, …).
    final single = _singleCharReplacements[char];
    if (single != null) {
      out.write(single);
      continue;
    }
    // Already pure ASCII grapheme — keep it.
    if (char.codeUnits.every((u) => u >= 0x20 && u < 0x7F)) {
      out.write(char);
      continue;
    }
    // Last-resort placeholder so the BitBox firmware never sees a non-ASCII
    // byte. If a user ever hits this branch, please extend the maps above
    // with their script's transliteration.
    out.write('?');
  }
  return out.toString();
}
