import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/screens/pin/bloc/auth/pin_auth_cubit.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/setup/routing/boot_navigation.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';

/// Custom URL scheme the app is opened with. Registered in
/// `ios/Runner/Info.plist` (`CFBundleURLSchemes`) and
/// `android/app/src/main/AndroidManifest.xml` (VIEW intent-filter).
const String appLinkScheme = 'realunit-wallet';

/// Canonical button target the website links to. Any `realunit-wallet://…` URL
/// works — this is just the agreed, stable one.
const String appLinkUrl = 'realunit-wallet://open';

/// Cold-start fallback location (see [appLinkSchemeRedirect]) — the router's
/// normal entry, identical to `GoRouter.initialLocation`.
const String appLinkColdStartLocation = '/home';

/// Detects and extracts a DFX OpenCryptoPay payment payload out of a
/// `realunit-wallet:…` deeplink.
///
/// The DFX `/pl` frontend builds the deeplink generically as
/// `{deepLink}lightning:{LNURL}` with the backend `deepLink='realunit-wallet:'`
/// (no `//`), so the app normally receives `realunit-wallet:lightning:<LNURL>`
/// — a double-colon OPAQUE URI. Some OS layer may instead normalize it to
/// `realunit-wallet://lightning:<LNURL>`; both are handled here.
///
/// Works on the raw URI STRING, not `Uri` component accessors: this is an
/// opaque URI, not a hierarchical one, so `.host`/`.path` are not a reliable
/// general parsing strategy for both variants.
///
/// Returns the payload to feed into `PayScanCubit.onCodeDetected` VERBATIM
/// (e.g. `lightning:LNURL1...`, a bare `LNURL1...`, or a bare `https://...`
/// lnurlp URL), or null when [rawUri] is not a recognized payment deeplink —
/// including the canonical path-less open and any other path-carrying scheme
/// URL, which stay on the existing no-op / rewrite path in
/// [appLinkSchemeRedirect]. No validation beyond this structural sniff: a
/// malformed match is still returned and left for `LnurlDecoder` (reached via
/// `onCodeDetected`) to reject — this function must not swallow or
/// pre-validate (no silent fallback).
String? extractPaymentDeeplinkPayload(String rawUri) {
  const prefix = '$appLinkScheme:';
  if (!rawUri.startsWith(prefix)) return null;
  var remainder = rawUri.substring(prefix.length);
  if (remainder.startsWith('//')) remainder = remainder.substring(2);
  if (remainder.isEmpty) return null;

  final isLightning = remainder.startsWith('lightning:');
  final isBareLnurl = remainder.toUpperCase().startsWith('LNURL');
  final isHttpLnurlp = remainder.startsWith('http://') || remainder.startsWith('https://');
  if (!isLightning && !isBareLnurl && !isHttpLnurlp) return null;
  return remainder;
}

/// Top-level go_router redirect for custom-scheme opens.
///
/// A `realunit-wallet://…` open (canonical `realunit-wallet://open`) only brings
/// the app to the foreground — it must NOT force any in-app navigation.
///
/// Cold start: there is no prior in-app route ([currentLocation] is empty or
/// the scheme URL itself), so it hands off to the normal boot entry and lets
/// `main.dart`'s boot flow take over — the PIN gate and boot ordering stay
/// untouched.
///
/// Warm resume, canonical path-less open (`realunit-wallet://open`): it returns
/// `null` so the scheme URL stays unmatched and falls through to
/// [appLinkOnException], which keeps the current route configuration untouched
/// — a true no-op. Returning a location string here instead would be applied as
/// a `go` and REPLACE the whole match list: an imperatively pushed route (the
/// KYC flow from Buy/Sell) would be dropped together with its page-scoped
/// state, its `extra`, and the back stack underneath it.
///
/// Warm resume, scheme URL CARRYING a path: go_router matches on `uri.path`
/// alone, so `realunit-wallet://open/settings/seed` would match — and with a
/// `null` return it would navigate, straight past flow-level gates (the seed
/// page's PIN gate lives in the settings navigation path, not on the route).
/// Returning the current location instead would be no safer: applied as a
/// `go`, it rebuilds a pushed `extra`-required route (`/buyPaymentDetails`,
/// `/webView`, …) with a null `extra` and crashes its builder cast. So crafted
/// path-carrying URLs are rewritten to the canonical [appLinkUrl]: go_router
/// resolves the rewritten URL to an unmatched (error) match list and
/// short-circuits before any further redirect pass, so the chain terminates
/// and [appLinkOnException] keeps the configuration — the same true no-op as
/// the canonical open, with no rebuild at all.
///
/// Payment-deeplink carve-out: when the scheme URL carries a DFX OpenCryptoPay
/// payload (see [extractPaymentDeeplinkPayload]), the same security properties
/// still hold.
///
/// Warm resume, unlocked (`isInAppRoute` and not a [isGateLocation] path): the
/// redirect itself still returns `null` — a true no-op for the match list /
/// back-stack / `extra` — and the actual navigation is an imperative
/// `pushNamed` deferred to `addPostFrameCallback`, so it lands on top of
/// whatever is currently pushed without replacing it. The deferred callback
/// re-checks [PinAuthCubit.state.isPinVerified] at execution time: a location
/// snapshot can still show an unlocked path while an independent app-resume
/// re-lock (`AppLifecycleState.resumed` → `PinAuthCubit.onAppResumed()`) has
/// already landed between decision and push. If no longer verified, the
/// payload is stashed in [pendingPaymentDeeplink] instead — same post-unlock
/// replay path as the warm-locked branch.
///
/// Warm resume, locked (`isInAppRoute` but current path is a PIN/unlock gate
/// such as `/verifyPin`): the app is still on a lock gate. The payload is
/// stashed in [pendingPaymentDeeplink] and the redirect returns `null` so the
/// gate stays put — never push `/pay` over the lock screen. The stash is
/// replayed only once the PIN/unlock gate ladder lands on the dashboard
/// ([applyBootNavAction]'s dashboard branch), never before — same post-unlock
/// replay path as a cold start.
///
/// Cold start (`!isInAppRoute`): the payload is stashed in
/// [pendingPaymentDeeplink] and the redirect hands off to
/// [appLinkColdStartLocation] so the normal PIN/unlock gate ladder runs first;
/// [applyBootNavAction] replays the payload as an imperative `/pay` push only
/// once that ladder lands on the dashboard.
///
/// Non-scheme (in-app) navigation is left untouched (`null`).
//
// @no-integration-test: OS-level custom-scheme delivery and foregrounding can
// only be exercised on a real device, and no integration_test/ harness exists
// in this repo yet. The redirect is covered by widget tests in
// app_link_entry_test.dart.
String? appLinkSchemeRedirect(GoRouterState state, String currentLocation, GoRouter router) {
  if (state.uri.scheme != appLinkScheme) return null;
  final current = Uri.parse(currentLocation);
  final isInAppRoute = current.scheme.isEmpty && current.path.startsWith('/');

  final paymentPayload = extractPaymentDeeplinkPayload(state.uri.toString());
  if (paymentPayload != null) {
    if (isInAppRoute && !isGateLocation(current.path)) {
      // Warm resume, unlocked: the app is already past the lock gates. This
      // redirect pass itself still returns null — a true no-op identical to
      // the canonical open — so the current match list / back-stack / extra
      // stay untouched. The actual navigation is an imperative pushNamed
      // deferred to addPostFrameCallback (calling into the router
      // synchronously from inside its own redirect is reentrant/unsafe): it
      // lands on top of whatever is currently pushed, never replacing it.
      // TOCTOU: the unlock decision above is from a location snapshot only;
      // independent AppLifecycleState.resumed → PinAuthCubit.onAppResumed()
      // can re-lock between that decision and the deferred frame. The
      // callback re-checks isPinVerified at execution time before pushing.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Re-check at execution time: the decision above was made from a
        // location snapshot, but the push is deferred to the next frame with
        // no ordering guarantee against an independent re-lock (app resume →
        // PinAuthCubit.onAppResumed() can land in between). Only push if
        // still genuinely unlocked; otherwise stash for post-unlock replay —
        // same stash/replay path as the warm-locked branch below.
        if (!getIt<PinAuthCubit>().state.isPinVerified) {
          pendingPaymentDeeplink = paymentPayload;
          return;
        }
        unawaited(router.pushNamed(AppRoutes.pay, extra: paymentPayload));
      });
      return null;
    }
    if (isInAppRoute) {
      // Warm resume, locked: current path is a PIN/unlock gate. Stash the
      // payload and stay on the gate — never push /pay over the lock screen.
      // applyBootNavAction replays the stash only after the gate ladder lands
      // on the dashboard (same post-unlock path as a cold-start stash).
      pendingPaymentDeeplink = paymentPayload;
      return null;
    }
    // Cold start: the PIN gate and boot ladder have not run yet. Stash the
    // payload; applyBootNavAction (boot_navigation.dart) replays it as an
    // imperative /pay push strictly after resolveBootNavigation lands on the
    // dashboard — i.e. after the very same PIN/unlock gate ladder a normal
    // /pay navigation passes, never before.
    pendingPaymentDeeplink = paymentPayload;
    return appLinkColdStartLocation;
  }

  if (!isInAppRoute) return appLinkColdStartLocation;
  final hasPath = state.uri.path.isNotEmpty && state.uri.path != '/';
  return hasPath ? appLinkUrl : null;
}

/// go_router exception handler paired with [appLinkSchemeRedirect].
///
/// With an `onException` handler installed, go_router keeps the current route
/// configuration whenever a URL matches no route (go_router `router.dart`:
/// "Avoid updating GoRouterDelegate if onException is provided"). A warm
/// custom-scheme open is exactly that case — [appLinkSchemeRedirect] lets it
/// fall through unmatched — so doing nothing here IS the foregrounding no-op,
/// and it is the only variant that survives imperatively pushed routes.
/// Cold-start scheme opens never reach this handler; the redirect already
/// mapped them to [appLinkColdStartLocation].
//
// @no-integration-test: OS-level custom-scheme delivery and foregrounding can
// only be exercised on a real device, and no integration_test/ harness exists
// in this repo yet. The handler is covered by widget tests in
// app_link_entry_test.dart.
void appLinkOnException(BuildContext context, GoRouterState state, GoRouter router) {
  if (state.uri.scheme == appLinkScheme) return;
  // A non-scheme URL that matches no route is a programming error. Installing
  // onException removes go_router's default error screen, so fail loud where
  // tests and debug builds can see it; in release the user stays on the
  // current screen instead of landing on an error page.
  assert(false, 'No route matches ${state.uri}');
}
