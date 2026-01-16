import 'package:realunit_wallet/generated/i18n.dart';

enum Language {
  en('en', 'assets/images/flags/gbr.png'),
  de('de', 'assets/images/flags/deu.png');

  const Language(this.code, this.imagePath);

  factory Language.fromCode(String code) => Language.values.firstWhere((e) => e.code == code);

  final String code;
  final String imagePath;

  String get name {
    switch (this) {
      case Language.en:
        return S.current.languageEnglish;
      case Language.de:
        return S.current.languageGerman;
    }
  }
}
