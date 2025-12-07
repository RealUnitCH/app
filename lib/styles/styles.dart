import 'package:flutter/material.dart';
import 'package:realunit_wallet/styles/colors.dart';

const kPrimaryButtonTextStyle = TextStyle(fontSize: 16, color: Colors.white);

const kPageTitleTextStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w700,
  color: RealUnitColors.realUnitBlack,
);

const kTitleTextStyle =
    TextStyle(fontSize: 16, color: RealUnitColors.realUnitBlack);

const kSubtitleTextStyle =
    TextStyle(fontSize: 14, color: DEuroColors.neutralGrey);

const kActionButtonTextStyle =
    TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600);

final kFullwidthPrimaryButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: Colors.white.withAlpha(50),
  fixedSize: Size(double.infinity, 55),
  elevation: 0.0,
);

final kFullwidthGrayButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: RealUnitColors.neutral100,
  fixedSize: const Size(double.infinity, 20),
  elevation: 0.0,
  textStyle: kFullwidthGrayButtonTextStyle,
);

const kFullwidthGrayButtonTextStyle = TextStyle(
  fontSize: 16,
  color: RealUnitColors.neutral900,
  fontWeight: FontWeight.w600,
);

final kFullwidthBlueButtonStyle = FilledButton.styleFrom(
  backgroundColor: RealUnitColors.realUnitBlue,
  fixedSize: const Size(double.infinity, 20),
  padding: const EdgeInsets.only(left: 24, right: 24),
);

const kFullwidthBlueButtonTextStyle =
    TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500);

final kFullwidthSecondaryButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: Colors.black.withAlpha(50),
  fixedSize: Size(double.infinity, 55),
  elevation: 0.0,
);

final kBalanceBarActionButtonStyle = FilledButton.styleFrom(
  backgroundColor: Colors.white.withAlpha(50),
  textStyle: kPrimaryButtonTextStyle,
  padding: EdgeInsets.only(top: 5, bottom: 5, left: 10, right: 10),
);

final kFullwidthActionButtonStyle = FilledButton.styleFrom(
    backgroundColor: DEuroColors.neutralGrey.withAlpha(50),
    padding: EdgeInsets.only(top: 5, bottom: 5, left: 10, right: 10),
    iconColor: DEuroColors.neutralGrey);

const kContainerCardStyle = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(12)),
);

const kBottonSheetTitleTextStyle = TextStyle(
  fontSize: 22,
  fontWeight: FontWeight.w700,
  color: RealUnitColors.realUnitBlack,
);

const kBottonSheetContentTextStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  color: RealUnitColors.neutral500,
);
