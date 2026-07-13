import 'package:flutter/material.dart';

/// Column layout that keeps [actions] reachable on every viewport and text scale.
///
/// **Contract**
/// - [body] may grow with content / accessibility text — it scrolls when the
///   parent height is bounded.
/// - [actions] (primary/secondary CTAs) stay **outside** the scroll view so they
///   never leave the hit-testable region (the BitBox pairing regression).
/// - When height is unbounded (e.g. a bare `testWidgets` pump without a sheet
///   height), body and actions stack with `MainAxisSize.min` so layout still
///   succeeds; production hosts must bound height (sheet / `Expanded` / page).
///
/// Use this for every bottom sheet and full-screen flow that combines long copy
/// with bottom CTAs. Do not put a [Spacer] above buttons and hope it fits.
class ScrollableActionsLayout extends StatelessWidget {
  const ScrollableActionsLayout({
    super.key,
    required this.body,
    this.actions = const [],
    this.padding = EdgeInsets.zero,
    this.bodyPadding = EdgeInsets.zero,
    this.actionsPadding = EdgeInsets.zero,
    this.actionsSpacing = 12,
    this.scrollPhysics,
  });

  /// Scrollable main content (illustration, titles, forms, hints).
  final Widget body;

  /// Sticky action widgets, top-to-bottom (confirm above cancel).
  final List<Widget> actions;

  /// Outer padding around the whole layout.
  final EdgeInsetsGeometry padding;

  /// Extra padding inside the scroll view around [body].
  final EdgeInsetsGeometry bodyPadding;

  /// Padding around the sticky actions block.
  final EdgeInsetsGeometry actionsPadding;

  /// Vertical gap between action widgets.
  final double actionsSpacing;

  final ScrollPhysics? scrollPhysics;

  @override
  Widget build(BuildContext context) {
    final actionBlock = actions.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: actionsPadding,
            child: Column(
              mainAxisSize: .min,
              spacing: actionsSpacing,
              children: actions,
            ),
          );

    final scrollBody = SingleChildScrollView(
      physics: scrollPhysics,
      child: Padding(
        padding: bodyPadding,
        child: body,
      ),
    );

    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Unbounded height (some widget tests, intrinsic measuring): no
          // Expanded — just stack. Production sheets/pages pass a max height.
          if (!constraints.hasBoundedHeight) {
            return Column(
              mainAxisSize: .min,
              crossAxisAlignment: .stretch,
              children: [
                Padding(
                  padding: bodyPadding,
                  child: body,
                ),
                actionBlock,
              ],
            );
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
