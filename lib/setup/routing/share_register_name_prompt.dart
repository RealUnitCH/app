import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/setup/routing/effective_location.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';

bool _shareRegisterNamePromptInFlight = false;

@visibleForTesting
void debugResetShareRegisterNamePromptInFlight() {
  _shareRegisterNamePromptInFlight = false;
}

/// After a dashboard landing, asks the API whether an approved name still has
/// to be signed into the share register and opens KYC only when it does.
/// A second call while one is in flight returns. Any failure returns without
/// blocking boot. KYC opens only while the effective location is still the
/// dashboard; a gate, a flow, or any other route visible when the response
/// arrives is not covered.
Future<void> promptShareRegisterNameUpdate(GoRouter router) async {
  if (_shareRegisterNamePromptInFlight) return;
  _shareRegisterNamePromptInFlight = true;
  try {
    final info = await getIt<RealUnitRegistrationService>().getRegistrationInfo();
    if (!info.shareRegisterNameSigningRequired) return;
    final location = effectiveLocation(router.routerDelegate.currentConfiguration);
    final path = Uri.tryParse(location)?.path ?? location;
    if (path != Uri.parse(router.namedLocation(AppRoutes.dashboard)).path) return;
    await router.pushNamed(AppRoutes.kyc);
  } catch (_) {
    return;
  } finally {
    _shareRegisterNamePromptInFlight = false;
  }
}
