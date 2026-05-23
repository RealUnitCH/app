# Visual Regression Tests

Pixel-exact baseline tests for selected screens. The pilot covers 5 screens
(Welcome, Dashboard, Settings, Buy, Sell) with 8 baseline PNGs. Skalierung auf
alle 57 Page-Files ist das Folge-Ziel — wird in separaten PRs nachgezogen,
nicht in diesem Pilot-PR.

## Stack

| Component | Choice |
|---|---|
| Framework | [alchemist](https://pub.dev/packages/alchemist) 0.14.0 (Betterment) |
| Font | Open Sans, eingecheckt unter `assets/fonts/` (SIL OFL 1.1) |
| Render host | dfx01 self-hosted runner (Mac Studio M3 Ultra) — Labels `self-hosted, macOS, ARM64, m3-ultra, realunit-app` |
| Theme | `realUnitTheme` (light) aus `lib/styles/themes.dart` |
| CI job | `golden-tests` in `.github/workflows/pull-request.yaml` |

Baselines werden ausschliesslich auf dfx01 generiert und validiert. Lokales
`flutter test test/goldens/` schlägt erwartet mit Pixel-Drift fehl
(unterschiedliche Mac-Hardware/macOS-Versionen rendern Sub-Pixel-AA leicht
anders).

## Pilot scope

| Screen | Tests | File |
|---|---|---|
| Welcome | 2 (iOS, Android theme variant) | `test/goldens/screens/welcome/welcome_golden_test.dart` |
| Dashboard | 1 (empty balance) | `test/goldens/screens/dashboard/dashboard_golden_test.dart` |
| Settings | 1 (default, no open wallet) | `test/goldens/screens/settings/settings_golden_test.dart` |
| Buy | 2 (initial, payment-info-loaded) | `test/goldens/screens/buy/buy_golden_test.dart` |
| Sell | 2 (no account zero balance, with balance) | `test/goldens/screens/sell/sell_golden_test.dart` |

Baselines landen unter `test/goldens/screens/<feature>/goldens/macos/*.png`.

### Skipped: `web_view_page.dart`

The one `skip: true` in the suite. `InAppWebView` from `flutter_inappwebview` is a platform-view, not a regular widget — its rendering happens via the iOS/Android view-embedding API and has no headless representation in `flutter_test`.

Method-channel stubbing alone is **not enough**: the widget's first build asserts that `InAppWebViewPlatform.instance` is set, and that interface declares five abstract `createPlatform…` methods (controller, widget, cookie manager, etc.) — each returning another platform-view-bound class. A working stub would need ~50 lines of mock subclasses and would still render the body as a blank rectangle.

For a one-page edge case the cost/benefit doesn't justify it. The test is committed with `skip: true` and reactivates the moment someone wires up a full `InAppWebViewPlatform` mock — preferably published as a separate test-only package so other Flutter apps can reuse it.

## Initial bootstrap

The very first baseline set has to come from dfx01 itself. The pattern:

1. Open this PR as **Draft**. The `golden-tests` CI job will be red on the
   first push — no baselines exist yet.
2. Run the temporary `golden-bootstrap.yaml` workflow via
   `gh workflow run golden-bootstrap.yaml --ref feat/visual-regression-pilot -R DFXswiss/realunit-app`.
3. Wait for the run to complete; download the `golden-baselines` artifact:
   ```bash
   RUN_ID=$(gh run list --workflow=golden-bootstrap.yaml --limit 1 --json databaseId --jq '.[0].databaseId')
   gh run download "$RUN_ID" -n golden-baselines -D /tmp/baselines
   ```
4. Copy the PNGs into the repo, commit, push:
   ```bash
   rsync -a /tmp/baselines/ test/goldens/
   git add test/goldens/screens/**/goldens/
   git commit -m "test(goldens): commit initial baselines generated on dfx01"
   git push
   ```
5. Verify the `golden-tests` job goes green on the next CI run.
6. Delete `.github/workflows/golden-bootstrap.yaml` in the same PR before
   marking ready-for-review.

## Day-to-day workflow

### Adding a new golden test

1. Add a `*_golden_test.dart` under `test/goldens/screens/<feature>/`.
   Reuse the mock pattern from the existing pilot tests.
2. Open a Draft PR. The `golden-tests` job will be red because the new
   test has no committed baseline.
3. Trigger a one-off bootstrap on the branch — same flow as the initial
   bootstrap above, just generate, download, commit. Or, when the
   `golden-bootstrap.yaml` workflow has already been deleted from develop:
   reintroduce it on the branch and remove it again in the same PR.

### Reacting to a CI drift

CI shows the `Run visual regression tests` step red and an artifact
`golden-diffs` is uploaded. Open the artifact and inspect the diff PNG:

* **Intentional change** (you redesigned the UI): regenerate baselines on
  dfx01 (see "Adding a new golden test" above) and commit the new PNGs in
  the same PR as the UI change.
* **Regression** (UI shouldn't have moved): fix the code; CI returns to
  green when pixels match again.

Never silently re-record baselines to make CI green — review the diff
visually first.

### Flutter SDK bumps

A Flutter bump (`flutter-version` in `.github/workflows/*.yaml`) changes
Skia's text shaper or layout subtly. Goldens become stale. The bump PR
must regenerate all baselines:

```bash
# On the bump branch, on dfx01 (or via golden-bootstrap.yaml workflow):
flutter test test/goldens --update-goldens
git add test/goldens/screens/**/goldens/
git commit -m "test(goldens): regenerate after Flutter <new-version> bump"
```

### dfx01 outage fallback

If dfx01 is down (power, macOS update, service maintenance) and a PR is
blocked on `golden-tests`:

1. Switch `runs-on:` in `pull-request.yaml` for the `golden-tests` job
   from `[self-hosted, ..., realunit-app]` to `macos-15`.
2. Regenerate all baselines on `macos-15` in the same PR.
3. Merge. When dfx01 is back up, regenerate baselines on it in a separate
   PR and switch `runs-on:` back.

This path is intentionally manual — it's a notfall, not a routine. The
flipping of baselines between two hosts incurs a mass-PNG-change PR each
direction.

### macOS update on dfx01

The Mac Studio M3 Ultra runs macOS — updates change Skia/CoreText
versions slightly. Before applying a macOS update on dfx01:

1. Prepare a regenerate-baselines PR.
2. Apply the macOS update.
3. Run the regenerate workflow, commit, push, merge.

## Architecture notes

### Why `realunit-app` not `realunit-ios` as runner label?

The label registered in `DFXswiss/realunit-app` is `realunit-app`, not the
`realunit-ios` documented in `DFXServer/server` for the earlier Tier 3
Maestro plan. Goldens are headless Skia (no iOS Simulator), so an
`-ios`-suffixed label would be misleading. If the runner later picks up
Tier 3 Maestro work too (e.g. when the dfx01 capacity allows it), add the
`realunit-ios` label alongside the existing one — single runner, two
workload classes.

### Why pin Open Sans as an asset?

`lib/styles/text_styles.dart:4` declares `fontFamily: 'Open Sans'` but
the font was never an asset — Flutter fell back to the system font at
runtime. That fallback is not deterministic across macOS hosts. Goldens
require pixel-stable text rendering; the only honest fix is to ship the
font with the app. The 5 TTF variants (Regular, Italic, SemiBold, Bold,
BoldItalic) live under `assets/fonts/` with the SIL OFL 1.1 license file.

### Why dfx01 not GitHub-hosted macos-15?

Performance (M3 Ultra ~2-3× faster than the GitHub macOS hosted runner)
and Hardware-Determinismus (identical Skia/CoreText/HW across runs —
no GitHub image bump can drift the baselines). The cost argument does
**not** apply — `DFXswiss/realunit-app` is public, GitHub Actions on
public repos are free even for macOS minutes.
