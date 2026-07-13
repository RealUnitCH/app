import 'package:flutter/material.dart';

/// Column layout that keeps [actions] reachable on every viewport and text scale.
///
/// **Contract**
/// - [body] scrolls inside a [SingleChildScrollView] whenever it grows with
///   content or accessibility text scale.
/// - [actions] (primary/secondary CTAs) stay **outside** the scroll view, in a
///   sticky block below it, so they never leave the hit-testable region (the
///   BitBox pairing regression).
/// - This widget requires a **bounded height** (bottom sheet, `Expanded`, or a
///   `SizedBox`). Giving it an unbounded height is a programming error: there
///   would be no room to scroll and the sticky actions would be pushed out of
///   the hit-test region — exactly the bug this widget exists to prevent. An
///   unbounded height throws a [FlutterError] in every build mode (debug and
///   release), so the failure is always loud and never a silently degraded
///   layout.
///
/// Use this for every bottom sheet and full-screen flow that combines long copy
/// with bottom CTAs. Do not put a [Spacer] above buttons and hope it fits.
class ScrollableActionsLayout extends StatelessWidget {
  const ScrollableActionsLayout({
    super.key,
    required this.body,
    this.actions = const [],
    this.padding = EdgeInsets.zero,
    this.actionsSpacing = 12,
    this.scrollPhysics,
  });

  /// Scrollable main content (illustration, titles, forms, hints).
  final Widget body;

  /// Sticky action widgets, top-to-bottom (confirm above cancel).
  final List<Widget> actions;

  /// Outer padding around the whole layout.
  final EdgeInsetsGeometry padding;

  /// Vertical gap between action widgets.
  final double actionsSpacing;

  final ScrollPhysics? scrollPhysics;

  @override
  Widget build(BuildContext context) {
    final actionBlock = actions.isEmpty
        ? const SizedBox.shrink()
        : Column(
            mainAxisSize: .min,
            spacing: actionsSpacing,
            children: actions,
          );

    final scrollBody = SingleChildScrollView(
      physics: scrollPhysics,
      child: body,
    );

    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (!constraints.hasBoundedHeight) {
            throw FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary('ScrollableActionsLayout requires a bounded height.'),
              ErrorDescription(
                'It was given an unbounded height, so the body could not scroll and the '
                'sticky actions would be pushed out of the hit-test region — the exact '
                'bug this widget exists to prevent.',
              ),
              ErrorHint(
                'Host it in a bottom sheet, an Expanded, or a SizedBox with a fixed '
                'height. A Column(mainAxisSize: .min) hands its children an unbounded '
                'height and is not a valid host.',
              ),
            ]);
          }
          return Column(
            crossAxisAlignment: .stretch,
            children: [
              Expanded(child: scrollBody),
              actionBlock,
            ],
          );
        },
      ),
    );
  }
}
