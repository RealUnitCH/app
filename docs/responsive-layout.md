# Responsive layout & accessibility text

## Goal

Every standard phone (iOS mini/SE → Pro Max, Android compact → large) and every system text size (small → extreme accessibility) keeps **all primary actions tappable** and **all critical copy reachable** (scroll if needed).

This is independent of line-coverage %: it is **100 % coverage of the “CTA outside hit bounds” bug class** via a device × text-scale matrix and a catalog of surfaces.

## Production pattern

```dart
ScrollableActionsLayout(
  body: /* illustration, titles, forms, hints */,
  actions: [
    AppFilledButton(...), // primary
    AppFilledButton(variant: secondary, ...), // optional
  ],
);
```

Source: [`lib/widgets/scrollable_actions_layout.dart`](../lib/widgets/scrollable_actions_layout.dart).

| Do | Don't |
|---|---|
| Scroll long body | `Column` + `Spacer` + buttons with no scroll |
| Sticky actions under the scroll view | Buttons as last children of an overflowing `Column` |
| Bound sheet with `maxHeight` + scroll inside | Fixed height + non-scroll content that can exceed it |
| Cap large illustrations (`maxHeight`) | Always paint 200×200 art above multi-paragraph copy |

## Test pattern

```dart
for (final cell in kFullResponsiveMatrix) {
  testWidgets('mySheet · ${cell.id}', (tester) async {
    await expectNoLayoutOverflow(tester, () async {
      await pumpClippedSheet(tester, widget: sheet, mediaQuery: cell.mediaQuery);
    });
    await expectFullyTappable(
      tester,
      find.text('Bestätigen'),
      within: find.byType(MySheet),
    );
  });
}
```

Helpers:

- [`test/helper/responsive_matrix.dart`](../test/helper/responsive_matrix.dart) — devices + scales
- [`test/helper/layout_assertions.dart`](../test/helper/layout_assertions.dart) — overflow + hit-test tap
- [`test/helper/responsive_surface_catalog.dart`](../test/helper/responsive_surface_catalog.dart) — surfaces under the gate

## Rollout

1. **Done:** BitBox connect sheet (`ConnectContent` → `ScrollableActionsLayout` + full matrix).
2. **Next:** other bottom sheets with sticky CTAs (sell confirm, pin, support, …) — migrate layout, add catalog entry + matrix test in the same PR.
3. Full-page forms that already use `SingleChildScrollView` end-to-end: add matrix only if they also pin bottom actions without scroll.

## Manual smoke (optional, not the gate)

- Smallest phone + largest text in iOS/Android settings
- BitBox pairing with a real multi-token channel hash

Automated matrix is the merge gate; hardware smoke is a release checklist item only.
