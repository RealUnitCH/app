import 'package:realunit_wallet/generated/i18n.dart';

enum Currency {
  eur("EUR"),
  chf("CHF");

  const Currency(this.code);

  factory Currency.fromCode(String code) =>
      Currency.values.firstWhere((e) => e.code == code.toUpperCase());

  final String code;

  String get name {
    switch (this) {
      case Currency.eur:
        return S.current.currency_eur;
      case Currency.chf:
        return S.current.currency_chf;
    }
  }
}
