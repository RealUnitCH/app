import 'package:realunit_wallet/packages/service/dfx/models/referral/locale_text.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/referral_json_list.dart';

/// Wallet Markdown under assets/legal/referral_terms_*.md is the displayed text.
/// The API records the accepted version.
class ReferralTermsDto {
  static const bundledVersion = '2026-08-26';

  final String version;
  final String markdown;
  final String? markdownEn;

  const ReferralTermsDto({
    required this.version,
    required this.markdown,
    this.markdownEn,
  });

  String textForLang(String languageCode) {
    if (languageCode == 'en') {
      return firstNonEmpty([markdownEn, markdown]) ?? '';
    }
    return firstNonEmpty([markdown, markdownEn]) ?? '';
  }

  factory ReferralTermsDto.fromJson(Map<String, dynamic> json) {
    return ReferralTermsDto(
      version: referralJsonString(json['version']) ?? '',
      markdown: referralJsonString(json['markdown']) ?? '',
      markdownEn: referralJsonString(json['markdownEn']),
    );
  }
}
