import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/setup/routing/effective_location.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';

/// Tracks the topmost route of the navigator it observes. go_router's
/// configuration only lists page routes, so a dialog or bottom sheet shown
/// over the dashboard is invisible there; [promptShareRegisterNameUpdate] uses
/// this to avoid covering such a [PopupRoute] with `/kyc`.
class ShareRegisterNameRouteObserver extends NavigatorObserver {
  static final Expando<Route<dynamic>> _topRoutes = Expando<Route<dynamic>>();

  /// The topmost route of [navigator], or null when none was recorded yet.
  static Route<dynamic>? topRouteOf(NavigatorState navigator) => _topRoutes[navigator];

  // `didChangeTop` fires for every push/pop that changes the visible route,
  // including pageless dialogs and bottom sheets. Recording only here keeps
  // the answer authoritative: a page replace below an open popup cannot
  // clobber it.
  @override
  void didChangeTop(Route<dynamic> topRoute, Route<dynamic>? previousTopRoute) {
    super.didChangeTop(topRoute, previousTopRoute);
    final state = navigator;
    if (state != null) _topRoutes[state] = topRoute;
  }
}

bool _shareRegisterNamePromptInFlight = false;

/// Upper bound for the boot-time registration lookup so a hanging connection
/// cannot keep the prompt in flight for the rest of the session.
const _registrationInfoTimeout = Duration(seconds: 20);

@visibleForTesting
void debugResetShareRegisterNamePromptInFlight() {
  _shareRegisterNamePromptInFlight = false;
}

/// After a dashboard landing, asks the API whether an approved name still has
/// to be signed into the share register and opens KYC only when it does.
/// A second call while one is in flight returns. Any failure returns without
/// blocking boot. KYC opens only while the effective location is still the
/// dashboard; a gate, a flow, or any other route visible when the response
/// arrives is not covered. Likewise a dialog or bottom sheet on top of the
/// dashboard (e.g. the late referral-bind confirmation) stays uncovered.
Future<void> promptShareRegisterNameUpdate(GoRouter router) async {
  if (_shareRegisterNamePromptInFlight) return;
  _shareRegisterNamePromptInFlight = true;
  try {
    final info = await getIt<RealUnitRegistrationService>()
        .getRegistrationInfo()
        .timeout(_registrationInfoTimeout);
    if (!info.shareRegisterNameSigningRequired) return;
    final location = effectiveLocation(router.routerDelegate.currentConfiguration);
    final path = Uri.tryParse(location)?.path ?? location;
    if (path != Uri.parse(router.namedLocation(AppRoutes.dashboard)).path) return;
    if (_hasPopupRouteOnTop(router)) return;
    // Do not hold the gate across the push future: a gate `go` (re-lock,
    // updateRequired, ...) can replace the KYC route, in which case the push
    // future never completes and the prompt would stay disabled until restart.
    unawaited(router.pushNamed(AppRoutes.kyc));
  } catch (_) {
    return;
  } finally {
    _shareRegisterNamePromptInFlight = false;
  }
}

bool _hasPopupRouteOnTop(GoRouter router) {
  final navigator = router.routerDelegate.navigatorKey.currentState;
  if (navigator == null) return false;
  return ShareRegisterNameRouteObserver.topRouteOf(navigator) is PopupRoute;
}
