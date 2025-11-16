import 'package:realunit_wallet/styles/colors.dart';
import 'package:flutter/material.dart';

ThemeData get darkTheme => ThemeData(
  fontFamily: "Satoshi",
  colorScheme: ColorScheme.fromSeed(seedColor: DEuroColors.dEuroBlue),
  useMaterial3: true,
  scaffoldBackgroundColor: DEuroColors.neutralGrey98,
);
