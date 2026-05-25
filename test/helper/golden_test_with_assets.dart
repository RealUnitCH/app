import 'package:alchemist/alchemist.dart' as alchemist;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// Re-export the alchemist symbols that golden tests in this repo actually
// reference, so the direct `package:alchemist/alchemist.dart` import could be
// removed from each test file. Trimmed to actually-used symbols — extend only
// if a test starts using something else.
export 'package:alchemist/alchemist.dart'
    show
        PumpAction,
        PumpWidget,
        pumpOnce,
        pumpNTimes,
        onlyPumpWidget,
        precacheImages;

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
/// `SvgPicture` (flutter_svg) is **not** in scope of [precacheImages] — its
/// `bytesLoader` resolves quickly enough under the trailing `pumpAndSettle`
/// step of either `precacheImages` or `onlyPumpAndSettle` that existing
/// SVG-using pages (`welcome`, `create_wallet`, `settings_wallet_address`,
/// `kyc_email_verification`, `hardware_connect_bitbox`) already render
/// their SVGs correctly without dedicated preload. If a future SVG ends up
/// blank in a golden, the fix is to extend `precacheImages` here (not to
/// remove this wrapper).
///
/// All parameters and semantics are forwarded verbatim to alchemist's
/// [alchemist.goldenTest] — the only difference is the default value of
/// [pumpBeforeTest].
Future<void> goldenTest(
  String description, {
  required String fileName,
  required ValueGetter<Widget> builder,
  bool skip = false,
  // Default kept in lockstep with alchemist 0.14.0
  // (package:alchemist/src/golden_test.dart) so the `--exclude-tags golden`
  // filter in `pull-request.yaml`'s build job keeps matching.
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
