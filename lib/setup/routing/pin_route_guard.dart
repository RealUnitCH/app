import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/pin/bloc/auth/pin_auth_cubit.dart';
import 'package:realunit_wallet/screens/pin/verify_pin_page.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/setup/routing/effective_location.dart';
import 'package:realunit_wallet/setup/routing/routes/app_link_entry.dart';
import 'package:realunit_wallet/setup/routing/routes/pin_routes.dart';
import 'package:realunit_wallet/setup/routing/routes/settings_routes.dart';

/// Routes that open only directly after the PIN was entered on the step-up
/// gate ([PinRoutes.gate]). Open them with [pushAfterFreshPin].
const Set<String> freshPinRoutes = {
  SettingsRoutes.seed,
  SettingsRoutes.changePin,
};

/// Location a denied navigation is rewritten to. It matches no route, so
/// go_router hands it to [appLinkOnException], which keeps the current route
/// configuration: the user stays exactly where they are, pushed routes and
/// their `extra` included.
const String pinRouteGuardStay = appLinkUrl;

String? _freshPinGrant;

/// Opens [routeName] (one of [freshPinRoutes]) behind the PIN step-up gate.
///
/// The gate runs the normal PIN check with its lockout after failed attempts.
/// Only after it succeeds does this grant one navigation to [routeName] and
/// replace the gate with it. [pinRouteGuardRedirect] consumes the grant on the
/// very next navigation, so the route cannot be opened again without a new PIN.
Future<void> pushAfterFreshPin(
  BuildContext context, {
  required String routeName,
  String? description,
  Object? extra,
}) async {
  assert(freshPinRoutes.contains(routeName), '$routeName is not a fresh-PIN route');
  await context.pushNamed(
    PinRoutes.gate,
    extra: VerifyPinParams(
      description: description,
      onAuthenticated: () {
        _freshPinGrant = routeName;
        context.pushReplacementNamed(routeName, extra: extra);
      },
    ),
  );
}

/// Top-level redirect of the app router: links from outside the app first
/// ([appLinkSchemeRedirect]), then the PIN check ([pinRouteGuardRedirect]) for
/// every in-app navigation.
String? appRouterRedirect(GoRouterState state, GoRouter router) {
  final current = effectiveLocation(router.routerDelegate.currentConfiguration);
  return appLinkSchemeRedirect(state, current, router) ?? pinRouteGuardRedirect(state, current);
}

/// Drops a fresh-PIN grant that was not used yet.
@visibleForTesting
void clearFreshPinGrant() => _freshPinGrant = null;

/// Router-level PIN check, run by the top-level redirect on every navigation
/// after [appLinkSchemeRedirect].
///
/// URLs with a scheme are links from outside the app; [appLinkSchemeRedirect]
/// already turned them into a location that matches no route, so they are left
/// alone here. Every in-app navigation consumes the pending fresh-PIN grant,
/// whether it uses it or not. The decision itself is [resolvePinRouteGuard].
String? pinRouteGuardRedirect(GoRouterState state, String currentLocation) {
  if (state.uri.hasScheme) return null;
  final grant = _freshPinGrant;
  _freshPinGrant = null;
  final pin = getIt<PinAuthCubit>().state;
  return resolvePinRouteGuard(
    path: state.uri.path,
    currentLocation: currentLocation,
    locationOf: state.namedLocation,
    isLocked: isAppLocked(
      isPinSetup: pin.isPinSetup,
      isPinVerified: pin.isPinVerified,
      hasWallet: () => getIt<HomeBloc>().state.hasWallet,
    ),
    isPinSetup: pin.isPinSetup,
    freshPinRoute: grant,
  );
}

/// Whether the app is locked: a PIN is set, it was not entered since the last
/// lock, and there is a wallet to protect. This is the state in which the boot
/// ladder in `boot_navigation.dart` sends the user to the PIN prompt; without a
/// wallet the ladder runs the onboarding first and asks for the PIN afterwards.
bool isAppLocked({
  required bool isPinSetup,
  required bool isPinVerified,
  required bool Function() hasWallet,
}) => isPinSetup && !isPinVerified && hasWallet();

/// Pure decision of [pinRouteGuardRedirect]. Returns null to allow the
/// navigation to [path], or the location to go to instead.
///
/// - Locked ([isAppLocked]): every route except the PIN prompt leads to the
///   PIN prompt. When the PIN prompt is already showing, the user stays there.
/// - The PIN setup opens only while no PIN is set.
/// - A [freshPinRoutes] route opens only with the grant of
///   [pushAfterFreshPin] for exactly that route ([freshPinRoute]).
///
/// [locationOf] maps a route name to its location (`GoRouterState.namedLocation`).
String? resolvePinRouteGuard({
  required String path,
  required String currentLocation,
  required String Function(String name) locationOf,
  required bool isLocked,
  required bool isPinSetup,
  required String? freshPinRoute,
}) {
  final verifyLocation = locationOf(PinRoutes.verify);
  if (isLocked) {
    if (path == verifyLocation) return null;
    final onVerify = Uri.parse(currentLocation).path == verifyLocation;
    return onVerify ? pinRouteGuardStay : verifyLocation;
  }
  if (path == locationOf(PinRoutes.setup)) {
    return isPinSetup ? pinRouteGuardStay : null;
  }
  for (final routeName in freshPinRoutes) {
    if (path == locationOf(routeName)) {
      return routeName == freshPinRoute ? null : pinRouteGuardStay;
    }
  }
  return null;
}
