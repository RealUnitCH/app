import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/styles/themes.dart';

Widget wrapForGolden(
  Widget child, {
  ThemeData? theme,
  Locale locale = const Locale('de'),
}) {
  return MaterialApp(
    theme: theme ?? realUnitTheme,
    locale: locale,
    localizationsDelegates: [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: child,
    debugShowCheckedModeBanner: false,
  );
}
