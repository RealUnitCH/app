import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// `show` the test seam only — main.dart also declares a top-level `main`, which
// would otherwise clash with this file's own `main`.
import 'package:realunit_wallet/main.dart' show buildRealUnitErrorView;

void main() {
  // Pins the last-resort surface wired into `ErrorWidget.builder` in `main`.
  // It must render even when an uncaught build error escapes the MaterialApp /
  // localization scope, so the view brings its own Directionality and renders
  // as a bare root widget — these tests pump it with no surrounding app.
  group('RealUnit error view (ErrorWidget.builder surface)', () {
    testWidgets('renders the friendly copy and error icon with no surrounding app', (tester) async {
      await tester.pumpWidget(
        buildRealUnitErrorView(FlutterErrorDetails(exception: Exception('boom'))),
      );

      expect(find.text('Something went wrong. Please restart the app.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('surfaces the exception text in debug builds', (tester) async {
      await tester.pumpWidget(
        buildRealUnitErrorView(
          FlutterErrorDetails(exception: Exception('diagnostic-marker-123')),
        ),
      );

      // `flutter test` runs in debug mode, so the kDebugMode branch is live and
      // the raw exception text is surfaced to speed up diagnosis.
      expect(kDebugMode, isTrue);
      expect(find.textContaining('diagnostic-marker-123'), findsOneWidget);
    });
  });
}
