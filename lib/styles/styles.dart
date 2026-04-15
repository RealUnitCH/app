import 'package:flutter/material.dart';
import 'package:realunit_wallet/styles/colors.dart';

const kPageTitleTextStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w700,
  color: RealUnitColors.realUnitBlack,
);

const kTitleTextStyle = TextStyle(fontSize: 16, color: RealUnitColors.realUnitBlack);

const kActionButtonTextStyle = TextStyle(
  fontSize: 12,
  color: Colors.white,
  fontWeight: FontWeight.w600,
);

final kFullwidthGrayButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: RealUnitColors.neutral100,
  foregroundColor: RealUnitColors.neutral900,
);

final kFullwidthBlueButtonStyle = FilledButton.styleFrom(
  backgroundColor: RealUnitColors.realUnitBlue,
  fixedSize: const Size(double.infinity, 20),
  padding: const EdgeInsets.only(left: 24, right: 24),
);

const kFullwidthBlueButtonTextStyle = TextStyle(
  fontSize: 16,
  color: Colors.white,
  fontWeight: FontWeight.w500,
);

const kBottomSheetTitleTextStyle = TextStyle(
  fontSize: 22,
  fontWeight: FontWeight.w700,
  color: RealUnitColors.realUnitBlack,
);

const kBottomSheetContentTextStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  color: RealUnitColors.neutral500,
);
