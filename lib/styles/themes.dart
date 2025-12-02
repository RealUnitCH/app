import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:realunit_wallet/styles/colors.dart';

ThemeData get realUnitTheme => ThemeData(
      fontFamily: "Open Sans",
      colorScheme: ColorScheme.fromSeed(seedColor: RealUnitColors.realUnitBlue),
      useMaterial3: true,
      scaffoldBackgroundColor: RealUnitColors.neutral100,
      appBarTheme: AppBarTheme(
        scrolledUnderElevation: 0.0,
        backgroundColor: Colors.transparent,
        foregroundColor: RealUnitColors.realUnitBlack,
        iconTheme: IconThemeData(color: RealUnitColors.realUnitBlack),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark, // For Android
          statusBarBrightness: Brightness.light, // For iOS
        ),
      ),
    );
