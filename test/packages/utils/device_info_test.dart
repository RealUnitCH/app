import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/utils/device_info.dart';

void main() {
  // Save and restore the global platform override around each test so a
  // failure doesn't leak the override into later tests in the suite.
  final originalPlatform = debugDefaultTargetPlatformOverride;
  tearDown(() {
    debugDefaultTargetPlatformOverride = originalPlatform;
  });

  group('$DeviceInfo', () {
    test('iOS → isIOS=true, isMobile=true, isDesktop=false', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final d = DeviceInfo.instance;
      expect(d.isIOS, isTrue);
      expect(d.isAndroid, isFalse);
      expect(d.isMobile, isTrue);
      expect(d.isDesktop, isFalse);
    });

    test('Android → isAndroid=true, isMobile=true', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final d = DeviceInfo.instance;
      expect(d.isAndroid, isTrue);
      expect(d.isIOS, isFalse);
      expect(d.isMobile, isTrue);
      expect(d.isDesktop, isFalse);
    });

    test('macOS → isDesktop=true, isMobile=false', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

      final d = DeviceInfo.instance;
      expect(d.isDesktop, isTrue);
      expect(d.isMobile, isFalse);
      expect(d.isIOS, isFalse);
      expect(d.isAndroid, isFalse);
    });

    test('Windows + Linux are both desktop', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(DeviceInfo.instance.isDesktop, isTrue);

      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      expect(DeviceInfo.instance.isDesktop, isTrue);
    });

    test('Fuchsia falls into neither mobile nor desktop', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;

      final d = DeviceInfo.instance;
      expect(d.isMobile, isFalse);
      expect(d.isDesktop, isFalse);
    });
  });
}
