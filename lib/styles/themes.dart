import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:realunit_wallet/styles/colors.dart';

ThemeData get realUnitTheme => ThemeData(
      fontFamily: "Open Sans",
      colorScheme: ColorScheme.fromSeed(seedColor: RealUnitColors.realUnitBlue),
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
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
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(32.0),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          padding: WidgetStatePropertyAll(
            EdgeInsetsGeometry.symmetric(vertical: 14.0, horizontal: 20.0),
          ),
          backgroundColor: WidgetStateProperty.resolveWith<Color?>(
            (states) {
              if (states.contains(WidgetState.error)) {
                return RealUnitColors.status.red600;
              }
              if (states.contains(WidgetState.disabled)) {
                return RealUnitColors.neutral200;
              }
              return RealUnitColors.realUnitBlue;
            },
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>(
            (states) {
              if (states.contains(WidgetState.error)) {
                return RealUnitColors.basic.white;
              }
              if (states.contains(WidgetState.disabled)) {
                return RealUnitColors.neutral400;
              }
              return RealUnitColors.basic.white;
            },
          ),
          iconColor: WidgetStateProperty.resolveWith<Color?>(
            (states) {
              if (states.contains(WidgetState.error)) {
                return RealUnitColors.basic.white;
              }
              if (states.contains(WidgetState.disabled)) {
                return RealUnitColors.neutral400;
              }
              return RealUnitColors.basic.white;
            },
          ),
        ),
      ),
    );
