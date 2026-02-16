enum TimePeriod {
  oneWeek,
  oneMonth,
  threeMonths,
  oneYear,
  all
  ;

  String get name {
    switch (this) {
      case TimePeriod.oneWeek:
        return '1W';
      case TimePeriod.oneMonth:
        return '1M';
      case TimePeriod.threeMonths:
        return '3M';
      case TimePeriod.oneYear:
        return '1Y';
      case TimePeriod.all:
        return 'ALL';
    }
  }
}
