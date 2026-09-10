Future<String?> loadReferralTermsMarkdown({
  required String languageCode,
  required Future<String> Function(String assetPath) loadAsset,
}) async {
  final langs = <String>[
    languageCode,
    if (languageCode != 'de') 'de',
  ];
  for (final lang in langs) {
    try {
      final content = await loadAsset(
        'assets/legal/referral_terms_$lang.md',
      );
      if (content.trim().isNotEmpty) return content;
    } catch (_) {
      // Try the next language — EN asset missing still shows the DE TB.
    }
  }
  return null;
}
