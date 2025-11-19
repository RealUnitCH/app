import 'package:realunit_wallet/styles/colors.dart';
import 'package:flutter/material.dart';

ThemeData get darkTheme => ThemeData(
  fontFamily: "Open Sans",
  colorScheme: ColorScheme.fromSeed(seedColor: RealUnitColors.realUnitBlue),
  useMaterial3: true,
  scaffoldBackgroundColor: RealUnitColors.neutral100,
);
