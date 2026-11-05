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
/// blocking boot.
Future<void> promptShareRegisterNameUpdate(GoRouter router) async {
  if (_shareRegisterNamePromptInFlight) return;
  _shareRegisterNamePromptInFlight = true;
  try {
    final info = await getIt<RealUnitRegistrationService>().getRegistrationInfo();
    if (info.nameUpdateRequired != true) return;
    if (_locationIsKyc(router)) return;
    await router.pushNamed(AppRoutes.kyc);
  } catch (_) {
    return;
  } finally {
    _shareRegisterNamePromptInFlight = false;
  }
}

bool _locationIsKyc(GoRouter router) {
  final location = effectiveLocation(router.routerDelegate.currentConfiguration);
  final path = Uri.tryParse(location)?.path ?? location;
  return path == '/kyc' || path.startsWith('/kyc/');
}
