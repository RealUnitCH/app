Future<String?> loadReferralTermsMarkdown({
  required String languageCode,
  required Future<String> Function(String assetPath) loadAsset,
}) async {
  try {
    final content = await loadAsset(
      'assets/legal/referral_terms_$languageCode.md',
    );
    if (content.trim().isNotEmpty) return content;
  } catch (_) {
    // Missing locale file → Retry, same as LegalDocumentPage.
  }
  return null;
}
