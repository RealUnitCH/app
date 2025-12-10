import 'package:flutter/foundation.dart';

class DeviceInfo {
  DeviceInfo._();

  static DeviceInfo get instance => DeviceInfo._();

  bool get isMobile => [TargetPlatform.android, TargetPlatform.iOS].contains(defaultTargetPlatform);

  bool get isDesktop => [TargetPlatform.macOS, TargetPlatform.windows, TargetPlatform.linux]
      .contains(defaultTargetPlatform);
}
