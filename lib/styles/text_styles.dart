import 'package:flutter/material.dart';

class RealUnitTextStyle {
  static final header = _Header();
  static final body = _Body();

  static final theme = TextTheme(
    headlineLarge: RealUnitTextStyle.header.h1,
    headlineMedium: RealUnitTextStyle.header.h2,
    headlineSmall: RealUnitTextStyle.header.h4,
    bodyLarge: RealUnitTextStyle.body.base,
    bodyMedium: RealUnitTextStyle.body.sm,
    bodySmall: RealUnitTextStyle.body.xs,
  );
}

class _Header {
  final TextStyle h1 = const TextStyle(
    fontWeight: .w600,
    fontSize: 30,
    height: 40 / 30,
  );

  final TextStyle h2 = const TextStyle(
    fontWeight: .bold,
    fontSize: 26,
    letterSpacing: -0.52,
    height: 30 / 26,
  );

  final TextStyle h4 = const TextStyle(
    fontWeight: .bold,
    fontSize: 20,
    letterSpacing: -0.2,
    height: 24 / 20,
  );
}

class _Body {
  final TextStyle base = const TextStyle(
    fontWeight: .w400,
    fontSize: 16,
    height: 20 / 16,
  );

  final TextStyle sm = const TextStyle(
    fontWeight: .w400,
    fontSize: 14,
    height: 18 / 14,
  );

  final TextStyle xs = const TextStyle(
    fontWeight: .w400,
    fontSize: 12,
    height: 16 / 12,
  );
}
