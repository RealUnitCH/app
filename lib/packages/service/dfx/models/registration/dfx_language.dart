enum DfxLanguage {
  de,
  en,
  fr,
  it;

  @override
  String toString() {
    switch (this) {
      case DfxLanguage.de:
        return 'DE';
      case DfxLanguage.en:
        return 'EN';
      case DfxLanguage.fr:
        return 'FR';
      case DfxLanguage.it:
        return 'IT';
    }
  }
}
