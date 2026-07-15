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

The migration is repo-wide. **25 surfaces** are on `ScrollableActionsLayout` and
registered in [`kResponsiveSurfaceCatalog`](../test/helper/responsive_surface_catalog.dart)
— the BitBox connect sheet plus dashboard, create wallet, verify pin, the three KYC status
pages, KYC account-merge / merge-processing / link-wallet, KYC financial-data questions,
onboarding completed, support create-ticket, five settings_user_data edit/status subpages,
verify seed phrase, restore wallet, buy, sell, setup PIN, and the two CTA-less KYC static
pages (failure / signature-unsupported).

A follow-up sweep of this branch found and fixed 3 surfaces the original grep
(`Spacer()` + `AppFilledButton`/`FilledButton`) had missed, because each either used a
custom button widget or had no CTA at all: `setup_pin_page`, `kyc_failure_page`, and
`kyc_signature_unsupported_page` (the last two ship with an empty `actions: []` — there is
no CTA, but the message now scrolls instead of clipping). A parallel workstream separately
migrated `verify_seed_page`, `restore_wallet_view`, `buy_page`, and `sell_page` off the bare
`Spacer()` shape. All 7 now have their own matrix test and are registered in
`kResponsiveSurfaceCatalog`.

The catalog is a living list reviewed manually, not a proof that every sticky-CTA (or
overflow-prone) surface in the app is covered — the 3-surface miss above is exactly why.
As of this branch, `grep -rl "Spacer()" lib/` finds hits only in
`lib/widgets/scrollable_actions_layout.dart` (the widget's own doc comment, not a usage)
and `lib/screens/dashboard/widgets/transaction_row.dart` (a horizontal `Row` use —
legitimate, not this bug class, left unchanged). No sticky-CTA surface currently matches
this grep signal.

That grep is not exhaustive either — it is the same limited signal that missed the 3
surfaces above in the first place. At least three more surfaces are still plausible,
un-re-audited candidates because they use a bounded, non-scrolling
`Column(mainAxisSize: .min, ...)` with no `Spacer()` and no scroll view: the sell
confirm/executed sheets (`sell_confirm_sheet.dart`, `sell_executed_sheet.dart`) and the two
PIN bottom sheets (`forgot_pin_bottom_sheet.dart`, `enable_biometric_bottom_sheet.dart`).
`welcome_page.dart` looks structurally safe (its entire body, including all interactive
cards, already lives inside one `SingleChildScrollView` with no separate sticky CTA) but
was not verified with a matrix test. None of these are confirmed either way — that is an
open item for the next review pass, not a claim of completeness.

## Manual smoke (optional, not the gate)

- Smallest phone + largest text in iOS/Android settings
- BitBox pairing with a real multi-token channel hash

Automated matrix is the merge gate; hardware smoke is a release checklist item only.
