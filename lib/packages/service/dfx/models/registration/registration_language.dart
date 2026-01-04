enum RegistrationLanguage {
  de,
  en,
  fr,
  it;

  @override
  String toString() {
    switch (this) {
      case RegistrationLanguage.de:
        return 'DE';
      case RegistrationLanguage.en:
        return 'EN';
      case RegistrationLanguage.fr:
        return 'FR';
      case RegistrationLanguage.it:
        return 'IT';
    }
  }
}
