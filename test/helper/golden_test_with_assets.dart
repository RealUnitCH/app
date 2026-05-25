import 'package:alchemist/alchemist.dart' as alchemist;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// Re-export alchemist's [PumpAction] helpers so existing tests that reference
// e.g. [pumpOnce] keep working after the direct `package:alchemist/alchemist.dart`
// import was removed in favour of this wrapper.
export 'package:alchemist/alchemist.dart'
    show
        PumpAction,
        PumpWidget,
        pumpOnce,
        pumpNTimes,
        onlyPumpAndSettle,
        onlyPumpWidget,
        precacheImages,
        Interaction,
        press,
        longPress;

/// Drop-in replacement for alchemist's [alchemist.goldenTest] that defaults
/// [pumpBeforeTest] to [alchemist.precacheImages] so that any [Image.asset],
/// [FadeInImage], or [DecoratedBox] image fills are fully loaded from the
/// [DefaultAssetBundle] before the golden snapshot is captured.
///
/// The default [pumpBeforeTest] in alchemist 0.14.0 ([alchemist.onlyPumpAndSettle])
/// cannot await the asynchronous I/O performed by [precacheImage] because it
/// runs outside of [WidgetTester.runAsync]. As a result, any page that mounts
/// an [Image.asset] would render an empty box in its golden — see
/// `home/goldens/macos/home_page_default.png` for the original regression.
///
/// Using [alchemist.precacheImages] inside [WidgetTester.runAsync] (which is
/// what alchemist's helper does) makes asset loading reliable for every
/// `Image.asset` / `FadeInImage` / `DecoratedBox` in the tree without
/// requiring per-test changes.
///
/// All parameters and semantics are forwarded verbatim to alchemist's
/// [alchemist.goldenTest] — the only difference is the default value of
/// [pumpBeforeTest].
Future<void> goldenTest(
  String description, {
  required String fileName,
  required ValueGetter<Widget> builder,
  bool skip = false,
  List<String> tags = const ['golden'],
  double textScaleFactor = 1.0,
  BoxConstraints constraints = const BoxConstraints(),
  alchemist.PumpAction pumpBeforeTest = alchemist.precacheImages,
  alchemist.PumpWidget pumpWidget = alchemist.onlyPumpWidget,
  alchemist.Interaction? whilePerforming,
}) {
  return alchemist.goldenTest(
    description,
    fileName: fileName,
    builder: builder,
    skip: skip,
    tags: tags,
    textScaleFactor: textScaleFactor,
    constraints: constraints,
    pumpBeforeTest: pumpBeforeTest,
    pumpWidget: pumpWidget,
    whilePerforming: whilePerforming,
  );
}
