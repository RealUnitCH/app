import 'dart:developer' as developer;

import 'package:realunit_wallet/packages/service/dfx/dfx_language_service.dart';
import 'package:realunit_wallet/styles/language.dart';

/// Translates the backend's enabled-language list into the local [Language]
/// type used by the settings picker.
///
/// API call site: [DfxLanguageService] → `GET /v1/language`. Only languages
/// the backend reports as `enable: true` are returned. Languages the API
/// surfaces that the current app build has no enum for (no flag asset, no
/// translation) are logged and skipped.
class SupportedLanguageRepository {
  final DfxLanguageService _languageService;

  SupportedLanguageRepository(DfxLanguageService languageService)
    : _languageService = languageService;

  Future<List<Language>> getEnabled() async {
    final languages = await _languageService.getAllLanguages();
    final result = <Language>[];
    for (final lang in languages) {
      if (!lang.enable) continue;
      final localized = _tryParse(lang.symbol);
      if (localized != null) {
        result.add(localized);
      } else {
        developer.log(
          'SupportedLanguageRepository: backend offers language '
          '"${lang.symbol}" but this app build has no Language enum value '
          'for it; skipping.',
        );
      }
    }
    return result;
  }

  Language? _tryParse(String symbol) {
    try {
      return Language.fromCode(symbol.toLowerCase());
    } catch (_) {
      return null;
    }
  }
}
