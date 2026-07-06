import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _noScreenshotChannel = MethodChannel('com.flutterplaza.no_screenshot_methods');

/// Stub the `no_screenshot` plugin's method channel so calls to
/// `screenshotOff` / `screenshotOn` / `screenshotStream` do not throw
/// `MissingPluginException` in headless golden tests.
///
/// Call from `setUpAll`. Pass [calls] to record the invoked method names
/// (for tests asserting the off/on contract).
void stubNoScreenshotChannel({List<String>? calls}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    _noScreenshotChannel,
    (call) async {
      calls?.add(call.method);
      return true;
    },
  );
}

/// Remove the stub installed by [stubNoScreenshotChannel].
void unstubNoScreenshotChannel() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    _noScreenshotChannel,
    null,
  );
}
