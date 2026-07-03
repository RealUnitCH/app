/// DTOs for `GET /v1/config` — the API's authoritative input validation
/// patterns. The app compiles these at runtime instead of hardcoding a copy
/// of the rules (see `DfxConfigService`).
library;

/// A single validation pattern as exposed by the API: a JavaScript `RegExp`
/// source plus its flags.
class DfxValidationFormatDto {
  final String pattern;
  final String flags;

  const DfxValidationFormatDto({required this.pattern, required this.flags});

  factory DfxValidationFormatDto.fromJson(Map<String, dynamic> json) {
    return DfxValidationFormatDto(
      pattern: json['pattern'] as String,
      flags: json['flags'] as String,
    );
  }

  /// Compiles the API-provided source/flags into a Dart [RegExp]. Maps the
  /// JavaScript flag characters this app cares about onto their Dart
  /// `RegExp` equivalents.
  RegExp toRegExp() {
    return RegExp(
      pattern,
      unicode: flags.contains('u'),
      multiLine: flags.contains('m'),
      caseSensitive: !flags.contains('i'),
      dotAll: flags.contains('s'),
    );
  }
}

/// The `formats` map of the config response. Mirrors the API DTO for type
/// safety only — the values themselves are the source of truth.
class DfxFormatsDto {
  final DfxValidationFormatDto swissPaymentText;

  const DfxFormatsDto({required this.swissPaymentText});

  factory DfxFormatsDto.fromJson(Map<String, dynamic> json) {
    return DfxFormatsDto(
      swissPaymentText: DfxValidationFormatDto.fromJson(
        json['swissPaymentText'] as Map<String, dynamic>,
      ),
    );
  }
}

class DfxConfigDto {
  final DfxFormatsDto formats;

  const DfxConfigDto({required this.formats});

  factory DfxConfigDto.fromJson(Map<String, dynamic> json) {
    return DfxConfigDto(
      formats: DfxFormatsDto.fromJson(json['formats'] as Map<String, dynamic>),
    );
  }
}
