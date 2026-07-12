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
/// the app to the foreground — it must NOT force any in-app navigation. So on a
/// warm resume it keeps the user exactly where they were: [currentLocation] is
/// the router's current in-app route, returned unchanged (a no-op). On a cold
/// start there is no prior in-app route (currentLocation is empty or the scheme
/// URL itself), so it hands off to the normal boot entry and lets `main.dart`'s
/// boot flow take over — the PIN gate and boot ordering stay untouched. Either
/// way go_router never shows an error screen for a scheme URL that matches no
/// path route. Non-scheme (in-app) navigation is left untouched (`null`).
//
// @no-integration-test: OS-level custom-scheme delivery and foregrounding can
// only be exercised on a real device, and no integration_test/ harness exists
// in this repo yet. The redirect itself is covered by widget tests in
// app_link_entry_test.dart.
String? appLinkSchemeRedirect(GoRouterState state, String currentLocation) {
  if (state.uri.scheme != appLinkScheme) return null;
  final current = Uri.parse(currentLocation);
  final isInAppRoute = current.scheme.isEmpty && current.path.startsWith('/');
  return isInAppRoute ? currentLocation : appLinkColdStartLocation;
}
