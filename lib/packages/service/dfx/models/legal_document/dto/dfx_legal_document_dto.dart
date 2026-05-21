// Mirror of `LegalDocumentDto` on the API
// (`src/shared/models/legal-document/dto/legal-document.dto.ts`). The
// backend stores the URL + version per (type, language) pair and is the
// authority on which document version is current.

// Mirrors `enum LegalDocumentType` on the API
// (`src/shared/models/legal-document/legal-document.entity.ts`). String
// values match the serialized form returned by `/v1/legal-document`.
class LegalDocumentType {
  static const registrationAgreement = 'RegistrationAgreement';
  static const prospectus = 'Prospectus';
  static const aktionariatTerms = 'AktionariatTerms';
  static const aktionariatPrivacy = 'AktionariatPrivacy';
  static const dfxTerms = 'DfxTerms';
  static const dfxPrivacy = 'DfxPrivacy';
}

class DfxLegalDocumentDto {
  final int id;
  final String type;
  final String? language;
  final String version;
  final String url;

  const DfxLegalDocumentDto({
    required this.id,
    required this.type,
    this.language,
    required this.version,
    required this.url,
  });

  factory DfxLegalDocumentDto.fromJson(Map<String, dynamic> json) {
    return DfxLegalDocumentDto(
      id: json['id'] as int,
      type: json['type'] as String,
      language: json['language'] as String?,
      version: json['version'] as String,
      url: json['url'] as String,
    );
  }
}
