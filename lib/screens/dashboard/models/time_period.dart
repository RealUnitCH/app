import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';

enum TimePeriod {
  oneWeek,
  oneMonth,
  threeMonths,
  oneYear,
  all
  ;

  String name(BuildContext context) {
    switch (this) {
      case TimePeriod.oneWeek:
        return S.of(context).timePeriodOneWeekAbr;
      case TimePeriod.oneMonth:
        return S.of(context).timePeriodOneMonthAbr;
      case TimePeriod.threeMonths:
        return S.of(context).timePeriodThreeMonthsAbr;
      case TimePeriod.oneYear:
        return S.of(context).timePeriodOneYearAbr;
      case TimePeriod.all:
        return S.of(context).all;
    }
  }
}
