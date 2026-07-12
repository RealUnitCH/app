import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/utils/screenshot_guard.dart';

import '../../helper/golden_plugin_stubs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <String>[];

  setUp(() {
    calls.clear();
    ScreenshotGuard.reset();
    stubNoScreenshotChannel(calls: calls);
  });

  tearDown(unstubNoScreenshotChannel);

  group('$ScreenshotGuard', () {
    test('a single holder toggles the flag off and back on', () async {
      await ScreenshotGuard.acquire();
      expect(calls, ['screenshotOff']);

      await ScreenshotGuard.release();
      expect(calls, ['screenshotOff', 'screenshotOn']);
    });

    test('a stacked holder must not re-enable screenshots for the screen underneath', () async {
      await ScreenshotGuard.acquire(); // e.g. create-wallet showing seed words
      await ScreenshotGuard.acquire(); // verify-seed pushed on top
      expect(calls, ['screenshotOff'], reason: 'the flag is global — off once is off');

      await ScreenshotGuard.release(); // verify-seed popped
      expect(
        calls,
        ['screenshotOff'],
        reason: 'the screen underneath still shows seed material — screenshots stay blocked',
      );

      await ScreenshotGuard.release(); // create-wallet closed
      expect(calls, ['screenshotOff', 'screenshotOn']);
    });

    test('an unbalanced release is a no-op', () async {
      await ScreenshotGuard.release();
      expect(calls, isEmpty);
    });
  });
}
