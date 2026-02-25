import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/text_styles.dart';

ThemeData get realUnitTheme => ThemeData(
  fontFamily: RealUnitTextStyle.fontFamily,
  textTheme: RealUnitTextStyle.theme,
  colorScheme: ColorScheme.fromSeed(
    seedColor: RealUnitColors.realUnitBlue,
  ),
  useMaterial3: true,
  scaffoldBackgroundColor: RealUnitColors.basic.white,
  appBarTheme: AppBarTheme(
    scrolledUnderElevation: 0.0,
    backgroundColor: Colors.transparent,
    foregroundColor: RealUnitColors.realUnitBlack,
    iconTheme: const IconThemeData(
      color: RealUnitColors.realUnitBlack,
    ),
    centerTitle: true,
    titleTextStyle: RealUnitTextStyle.body.sm.copyWith(
      fontWeight: .bold,
      color: RealUnitColors.realUnitBlack,
    ),
    systemOverlayStyle: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // For Android
      statusBarBrightness: Brightness.light, // For iOS
    ),
  ),
  actionIconTheme: ActionIconThemeData(
    backButtonIconBuilder: (context) => const Icon(
      Icons.arrow_back_rounded,
    ),
  ),
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: RealUnitColors.basic.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(32.0),
      ),
    ),
  ),
  dropdownMenuTheme: DropdownMenuThemeData(
    menuStyle: MenuStyle(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: ButtonStyle(
      padding: const WidgetStatePropertyAll(
        EdgeInsetsGeometry.symmetric(vertical: 14.0, horizontal: 20.0),
      ),
      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.error)) {
          return RealUnitColors.status.red600;
        }
        if (states.contains(WidgetState.disabled)) {
          return RealUnitColors.neutral200;
        }
        return RealUnitColors.realUnitBlue;
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.error)) {
          return RealUnitColors.basic.white;
        }
        if (states.contains(WidgetState.disabled)) {
          return RealUnitColors.neutral400;
        }
        return RealUnitColors.basic.white;
      }),
      iconColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.error)) {
          return RealUnitColors.basic.white;
        }
        if (states.contains(WidgetState.disabled)) {
          return RealUnitColors.neutral400;
        }
        return RealUnitColors.basic.white;
      }),
      textStyle: WidgetStateTextStyle.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return RealUnitTextStyle.body.base.copyWith(fontWeight: .w600);
        }
        return RealUnitTextStyle.body.base.copyWith(fontWeight: .w600);
      }),
    ),
  ),
);
