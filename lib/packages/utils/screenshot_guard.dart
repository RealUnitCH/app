import 'package:flutter/foundation.dart';
import 'package:no_screenshot/no_screenshot.dart';

/// Ref-counted wrapper around the screenshot toggle: `no_screenshot` flips ONE
/// global window flag, so a protected screen popped off another protected
/// screen (e.g. verify-seed over create-wallet) must not re-enable screenshots
/// while seed material is still visible underneath.
class ScreenshotGuard {
  ScreenshotGuard._();

  static int _holders = 0;

  static Future<void> acquire() async {
    if (++_holders == 1) await NoScreenshot.instance.screenshotOff();
  }

  static Future<void> release() async {
    if (_holders == 0) return;
    if (--_holders == 0) await NoScreenshot.instance.screenshotOn();
  }

  @visibleForTesting
  static void reset() => _holders = 0;
}
