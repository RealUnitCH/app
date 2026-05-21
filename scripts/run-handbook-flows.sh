#!/usr/bin/env bash
#
# Re-capture every handbook screenshot from a running iOS Simulator.
#
# For each flow in .maestro/handbook/*.yaml (alphabetical order):
#   1. run the Maestro flow — navigates to the screen we want to document
#   2. take a screenshot via `xcrun simctl io booted screenshot`
#
# Why not Maestro's built-in `takeScreenshot`?
#   Maestro screenshots go through XCUITest, which renders the view-hierarchy
#   bitmap. Flutter screens that use `BackdropFilter` (e.g. SeedBlurCard on
#   the seed-backup pages) live on a GPU layer outside that bitmap and come
#   out as solid black PNGs. `xcrun simctl io booted screenshot` uses the
#   simulator's compositor and captures the actual final frame.
#
# Required:
#   * iOS Simulator booted with Runner.app installed (`flutter build ios
#     --simulator --debug` then `xcrun simctl install booted ...Runner.app`)
#   * maestro CLI on PATH (or at $HOME/.maestro/bin/maestro)
#
# Locale:
#   The booted simulator's locale is pinned to de_CH because the handbook
#   flows assert on German UI strings (e.g. "Digitale Wallet", "Erstellen
#   Sie Ihre PIN", "Einstellungen"). Local devs running this script will
#   have their simulator locale temporarily overridden; `simctl erase` on
#   the next run brings it back to defaults. CI runners default to en_US
#   without this pin and would fail the first German-string assertion.
#
# Retry strategy:
#   The Maestro 2.5.x driver intermittently hangs at XCUITest startup
#   on macos-latest + iOS 26.x (see mobile-dev-inc/maestro#3137). Each
#   flow is retried up to MAESTRO_MAX_ATTEMPTS times (default 3) when
#   the failure log contains `IOSDriverTimeoutException`. Assertion
#   failures are NEVER retried — those are real regressions and must
#   surface as red CI checks.
#
# Usage:  scripts/run-handbook-flows.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MAESTRO="${MAESTRO:-$HOME/.maestro/bin/maestro}"
FLOWS_DIR="$REPO_ROOT/.maestro/handbook"
SCREENS_DIR="$REPO_ROOT/docs/handbook/screenshots"

mkdir -p "$SCREENS_DIR"

if [ ! -x "$MAESTRO" ] && ! command -v maestro >/dev/null 2>&1; then
  echo "error: maestro CLI not found (expected at $MAESTRO or on PATH)" >&2
  exit 1
fi

if ! xcrun simctl list devices booted 2>/dev/null | grep -q Booted; then
  echo "error: no booted iOS simulator. Boot one and install Runner.app first." >&2
  exit 1
fi

# Maestro's `clearState` clears NSUserDefaults but does NOT clear the iOS
# Keychain. The app stores the wallet seed and PIN in Keychain, so without
# a full uninstall/reinstall the next run boots straight to the app-lock
# screen instead of the welcome flow. Reinstall to guarantee a clean start.
APP_ID="swiss.realunit.app"
APP_BUNDLE="${APP_BUNDLE:-$REPO_ROOT/build/ios/iphonesimulator/Runner.app}"

if [ ! -d "$APP_BUNDLE" ]; then
  echo "error: $APP_BUNDLE not found. Run:" >&2
  echo "  flutter build ios --simulator --debug" >&2
  exit 1
fi

# iOS Keychain on the simulator survives both `clearState` and a reinstall.
# The wallet + PIN are stored in Keychain, so a stale device boots straight
# to the app-lock screen instead of the onboarding flow. The reliable way to
# get a clean state is `simctl erase`, which wipes the device.
UDID="$(xcrun simctl list devices booted -j | /usr/bin/python3 -c "
import json, sys
for r, devs in json.load(sys.stdin)['devices'].items():
    for d in devs:
        if d.get('state') == 'Booted':
            print(d['udid']); sys.exit(0)
")"
if [ -z "$UDID" ]; then
  echo "error: could not resolve booted device UDID" >&2
  exit 1
fi

echo "Resetting simulator $UDID for a clean Keychain"
xcrun simctl shutdown "$UDID"
xcrun simctl erase "$UDID"
xcrun simctl boot "$UDID"
xcrun simctl bootstatus "$UDID" -b >/dev/null

# Pin simulator locale to de_CH. The handbook flows assert on German UI
# strings (e.g. "Digitale Wallet", "Erstellen Sie Ihre PIN", "Einstellungen")
# because the app's default locale is de_CH. CI runners boot iOS simulators
# in en_US by default, which would fail every German-string assertion on
# the very first flow that has one. Local developers usually have their
# simulator in de_CH already, so re-captures locally and on CI now match.
# Run after `bootstatus -b` so the device is guaranteed ready for
# `simctl spawn`, and use `spawn` so the defaults land in the booted
# device's domain, not the host's NSGlobalDomain.
echo "Pinning simulator locale to de_CH"
xcrun simctl spawn "$UDID" defaults write -g AppleLanguages -array de_CH
xcrun simctl spawn "$UDID" defaults write -g AppleLocale -string de_CH

echo "Installing $APP_ID from $APP_BUNDLE"
xcrun simctl install "$UDID" "$APP_BUNDLE"

shopt -s nullglob
flows=("$FLOWS_DIR"/*.yaml)
if [ "${#flows[@]}" -eq 0 ]; then
  echo "error: no flow files found in $FLOWS_DIR" >&2
  exit 1
fi

# Sort for deterministic ordering — flow filename is the source of truth.
IFS=$'\n' flows=($(printf '%s\n' "${flows[@]}" | sort))
unset IFS

# xcrun simctl runs inside CoreSimulator which is sandboxed by macOS TCC and
# cannot write to ~/Documents directly. Stage to /tmp and `mv` afterwards.
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Worst-case the entire suite is 3 × 19 × ~1 min plus 3 × ~6 min
# driver-startup-timeout per failed attempt, which still fits inside
# the workflow's 30 min envelope.
MAESTRO_MAX_ATTEMPTS="${MAESTRO_MAX_ATTEMPTS:-3}"

# Maestro's `--debug-output` writes per-attempt view-hierarchy.json +
# screenshot + maestro.log into the given directory. On flow failure
# these are the only forensic data that show what was actually on the
# screen at the assertion point — much more useful than a `simctl io
# screenshot` taken after the flow exited (which captures whatever
# screen the failure left the app on, not the moment of failure).
MAESTRO_DEBUG_ROOT="$TMP_DIR/maestro-debug"
mkdir -p "$MAESTRO_DEBUG_ROOT"

for flow in "${flows[@]}"; do
  base="$(basename "$flow" .yaml)"
  tmp_png="$TMP_DIR/$base.png"
  png="$SCREENS_DIR/$base.png"
  echo
  echo "▶ $base"

  attempt=0
  while : ; do
    attempt=$((attempt + 1))
    flow_log="$TMP_DIR/$base.attempt-$attempt.log"
    debug_dir="$MAESTRO_DEBUG_ROOT/$base-attempt-$attempt"
    if "$MAESTRO" test --debug-output "$debug_dir" --flatten-debug-output "$flow" 2>&1 | tee "$flow_log"; then
      [ "$attempt" -gt 1 ] && echo "  passed on attempt $attempt"
      break
    fi
    # Only retry the upstream driver-hang class. Assertion failures
    # are real regressions and must surface red — never retry them.
    if grep -q 'IOSDriverTimeoutException' "$flow_log" && \
       [ "$attempt" -lt "$MAESTRO_MAX_ATTEMPTS" ]; then
      echo "  driver hang on attempt $attempt of $MAESTRO_MAX_ATTEMPTS; restarting simulator and retrying"
      xcrun simctl shutdown "$UDID" || true
      xcrun simctl boot "$UDID"
      xcrun simctl bootstatus "$UDID" -b >/dev/null
      continue
    fi
    # Real failure OR retries exhausted: post-mortem + exit.
    echo "--- POST-MORTEM: TCP loopback listeners ---"
    /usr/sbin/lsof -iTCP -sTCP:LISTEN -nP 2>/dev/null | grep -E 'IPv[46]|java|xctest|XCT|maestro' || true
    echo "--- POST-MORTEM: live maestro / XCT / xcodebuild processes ---"
    ps -A 2>/dev/null | grep -E 'maestro|XCT|xcodebuild' | grep -v grep || true
    echo "--- POST-MORTEM: simulator log (last 2 min) ---"
    xcrun simctl spawn "$UDID" log show \
      --predicate 'process == "XCTRunner" OR process CONTAINS "swiss.realunit.app"' \
      --last 2m --style compact 2>/dev/null | tail -200 || true
    echo "--- POST-MORTEM: copy Maestro debug-output for failure to screenshots dir ---"
    if [ -d "$debug_dir" ]; then
      # Surface the failure screenshot + view hierarchy in the
      # uploaded artifact so a reviewer can see what was on screen
      # at the assertion point without re-running locally.
      cp -R "$debug_dir" "$SCREENS_DIR/_debug-$base-attempt-$attempt" || true
    fi
    exit 1
  done

  xcrun simctl io booted screenshot "$tmp_png" >/dev/null
  mv "$tmp_png" "$png"
  echo "  captured → ${png#$REPO_ROOT/}"
done

echo
echo "Done. Screenshots in $SCREENS_DIR:"
ls -1 "$SCREENS_DIR"
