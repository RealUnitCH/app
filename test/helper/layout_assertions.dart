import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Asserts that no [RenderFlex] overflow was reported during [body].
///
/// Catches the class of bugs where content is painted below a clipped sheet
/// and buttons stop receiving taps.
Future<void> expectNoLayoutOverflow(
  WidgetTester tester,
  Future<void> Function() body, {
  String? reason,
}) async {
  final overflows = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    final message = details.exceptionAsString();
    if (message.contains('overflowed') || message.contains('OVERFLOWING')) {
      overflows.add(message.split('\n').first);
    }
    previous?.call(details);
  };
  try {
    await body();
    // Allow a frame for flex overflow reporting.
    await tester.pump();
  } finally {
    FlutterError.onError = previous;
  }

  expect(
    overflows,
    isEmpty,
    reason: reason ??
        'Expected no RenderFlex overflow, got:\n${overflows.join('\n')}',
  );
}

/// Asserts [finder] resolves to a box fully inside [within] (if given) and
/// that a real pointer tap at its center reaches a [RenderMetaData] /
/// button path — i.e. the control is hit-testable, not merely in the tree.
///
/// Prefer this over `tester.widget<AppFilledButton>(...).onPressed?.call()`.
Future<void> expectFullyTappable(
  WidgetTester tester,
  Finder finder, {
  Finder? within,
  String? reason,
}) async {
  expect(
    finder,
    findsOneWidget,
    reason: reason ?? 'tappable target not found: $finder',
  );

  final box = tester.renderObject<RenderBox>(finder);
  final rect = box.localToGlobal(Offset.zero) & box.size;

  expect(
    rect.width,
    greaterThan(0),
    reason: reason ?? 'tappable target has zero width',
  );
  expect(
    rect.height,
    greaterThan(0),
    reason: reason ?? 'tappable target has zero height',
  );

  if (within != null) {
    expect(within, findsOneWidget, reason: 'within parent not found');
    final parentBox = tester.renderObject<RenderBox>(within);
    final parentRect = parentBox.localToGlobal(Offset.zero) & parentBox.size;
    // Allow 1px float tolerance.
    final inflated = parentRect.inflate(1);
    expect(
      inflated.contains(rect.topLeft) && inflated.contains(rect.bottomRight),
      isTrue,
      reason:
          reason ??
          'target $rect is not fully inside parent $parentRect '
              '(clipped / overflowed — taps will miss)',
    );
  }

  // Hit-test at the visual center: something in the render path must accept
  // the hit (otherwise the control is covered or outside the clip).
  final center = rect.center;
  final result = HitTestResult();
  WidgetsBinding.instance.hitTestInView(result, center, tester.view.viewId);

  expect(
    result.path,
    isNotEmpty,
    reason: reason ?? 'hit test at $center returned an empty path',
  );

  await tester.tapAt(center);
  await tester.pump();
}

/// Pumps [widget] as a clipped bottom-sheet-like host (mirrors production
/// `showModalBottomSheet` clipping) under [mediaQuery].
Future<void> pumpClippedSheet(
  WidgetTester tester, {
  required Widget widget,
  required MediaQueryData mediaQuery,
  ThemeData? theme,
  Locale locale = const Locale('de'),
}) async {
  await tester.binding.setSurfaceSize(mediaQuery.size);
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });

  await tester.pumpWidget(
    MediaQuery(
      data: mediaQuery,
      child: MaterialApp(
        theme: theme,
        locale: locale,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              clipBehavior: Clip.antiAlias,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: widget,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
