import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stub the `no_screenshot` plugin's method channel so calls to
/// `screenshotOff` / `screenshotOn` / `screenshotStream` do not throw
/// `MissingPluginException` in headless golden tests.
///
/// Call from `setUpAll`.
void stubNoScreenshotChannel() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('com.flutterplaza.no_screenshot_methods'),
    (call) async => true,
  );
}
