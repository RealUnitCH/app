# Responsive layout & accessibility text

## Goal

Every standard phone (iOS mini/SE → Pro Max, Android compact → large) and every system text size (small → extreme accessibility) keeps **all primary actions tappable** and **all critical copy reachable** (scroll if needed).

This is independent of line-coverage %: a device × text-scale matrix plus a living catalog of surfaces gates the "CTA outside hit bounds" bug class for every surface the catalog lists. The catalog does not prove every sticky-CTA surface in the app is covered — see docs/testing.md.

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

**Contract details**

- **Bounded height required.** The host must give `ScrollableActionsLayout` a bounded height (bottom sheet, `Expanded`, or fixed-size `SizedBox`). Unbounded height throws a `FlutterError` in every build mode (debug and release) — fail-loud, not a silent broken layout.
- **`centerBody: true`** vertically centers `body` while it fits the viewport; once content outgrows the viewport, the body scrolls normally. Use this for screens that previously centered with `Spacer()` above and below.
- **`Spacer()` is illegal inside the body.** The body lives in a `SingleChildScrollView` (unbounded main axis); a `Spacer` there throws a RenderFlex "unbounded" exception. Prefer `centerBody: true` instead.

| Do | Don't |
|---|---|
| Scroll long body | `Column` + `Spacer` + buttons with no scroll |
| Sticky actions under the scroll view | Buttons as last children of an overflowing `Column` |
| Host with bounded height (sheet / `Expanded` / fixed `SizedBox`) | Unbounded height host (e.g. bare `Column(mainAxisSize: min)`) |
| `centerBody: true` for vertically centered content | `Spacer()` inside the scrollable body |
| Fix/cap sheet height (e.g. a fraction of screen height) + scroll inside | Fixed height + non-scroll content that can exceed it |
| Cap large illustrations (`maxHeight`) | Always paint 200×200 art above multi-paragraph copy |

## Test pattern

```dart
for (final cell in kFullResponsiveMatrix) {
  testWidgets('mySheet · ${cell.id}', (tester) async {
    await withTargetPlatform(cell.device.platform, () async {
      await expectNoLayoutOverflow(tester, () async {
        await pumpClippedSheet(
          tester,
          widget: sheet,
          mediaQuery: cell.mediaQuery,
        );
      });
      await expectFullyTappable(
        tester,
        find.text('Bestätigen'),
        within: find.byType(MySheet),
      );
    });
  });
}
```

Helpers:

- [`test/helper/responsive_matrix.dart`](../test/helper/responsive_matrix.dart) — devices + scales
- [`test/helper/layout_assertions.dart`](../test/helper/layout_assertions.dart) — overflow + hit-test tap
- [`test/helper/responsive_surface_catalog.dart`](../test/helper/responsive_surface_catalog.dart) — surfaces under the gate

## Rollout

The migration is repo-wide: **18 surfaces** are on `ScrollableActionsLayout` and registered in [`kResponsiveSurfaceCatalog`](../test/helper/responsive_surface_catalog.dart) — the BitBox connect sheet plus dashboard, create wallet, verify pin, the three KYC status pages, KYC account-merge / merge-processing / link-wallet, KYC financial-data questions, onboarding completed, support create-ticket, and five settings_user_data edit/status subpages.

The catalog is a living list reviewed manually, not a proof that every sticky-CTA surface in the app is covered. **Not yet migrated** (no `ScrollableActionsLayout` in these files): welcome page (`welcome_page.dart`), sell confirm/executed sheets, pin setup / biometric bottom sheets.

## Manual smoke (optional, not the gate)

- Smallest phone + largest text in iOS/Android settings
- BitBox pairing with a real multi-token channel hash

Automated matrix is the merge gate; hardware smoke is a release checklist item only.
