import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

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
/// Warm resume: it returns `null` so the scheme URL stays unmatched and falls
/// through to [appLinkOnException], which keeps the current route configuration
/// untouched — a true no-op. Returning a location string here instead would be
/// applied as a `go` and REPLACE the whole match list: an imperatively pushed
/// route (the KYC flow from Buy/Sell) would be dropped together with its
/// page-scoped state, its `extra`, and the back stack underneath it.
///
/// Non-scheme (in-app) navigation is left untouched (`null`).
//
// @no-integration-test: OS-level custom-scheme delivery and foregrounding can
// only be exercised on a real device, and no integration_test/ harness exists
// in this repo yet. The redirect + exception handler pair is covered by widget
// tests in app_link_entry_test.dart.
String? appLinkSchemeRedirect(GoRouterState state, String currentLocation) {
  if (state.uri.scheme != appLinkScheme) return null;
  final current = Uri.parse(currentLocation);
  final isInAppRoute = current.scheme.isEmpty && current.path.startsWith('/');
  return isInAppRoute ? null : appLinkColdStartLocation;
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
void appLinkOnException(BuildContext context, GoRouterState state, GoRouter router) {
  if (state.uri.scheme == appLinkScheme) return;
  // A non-scheme URL that matches no route is a programming error. Installing
  // onException removes go_router's default error screen, so fail loud where
  // tests and debug builds can see it; in release the user stays on the
  // current screen instead of landing on an error page.
  assert(false, 'No route matches ${state.uri}');
}
