import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/setup/routing/routes/onboarding_routes.dart';
import 'package:realunit_wallet/setup/routing/routes/pin_routes.dart';

/// Pure, router-agnostic decision for the boot/lock navigation state machine
/// driven by `main.dart`'s `_navigate`. Deliberately free of `go_router` and
/// `getIt` so the whole gate ladder can be unit-tested exhaustively.
sealed class BootNavAction {
  const BootNavAction();
}

/// The wallet is still loading — do not navigate yet, wait for the next
/// emission that flips `isLoadingWallet` off.
class BootNavWaitForLoad extends BootNavAction {
  const BootNavWaitForLoad();
}

/// All gates passed but the wallet is not in memory yet — trigger the load and
/// wait for the resulting HomeBloc emission.
class BootNavLoadWallet extends BootNavAction {
  const BootNavLoadWallet();
}

/// Navigate to a gate / landing route by its go_router name.
class BootNavGoNamed extends BootNavAction {
  final String routeName;
  const BootNavGoNamed(this.routeName);
}

/// Restore the in-flight (non-gate) route the user was on before the background
/// lock / re-lock, addressed by its location (path).
class BootNavRestore extends BootNavAction {
  final String location;
  const BootNavRestore(this.location);
}

/// All gates passed and the user is already on a valid non-gate route — leave
/// them exactly where they are, never yank them to the dashboard.
class BootNavStay extends BootNavAction {
  const BootNavStay();
}

/// Locations that are boot/lock gates and must never be restored: re-entering
/// one after a resume would either bypass a gate or be pointless. Every other
/// location is an in-app route worth restoring.
const Set<String> kGateLocations = {
  '/home',
  '/welcome',
  '/createWallet',
  '/restoreWallet',
  '/verifySeed',
  '/onboardingComplete',
  '/pinGate',
  '/setupPin',
  '/verifyPin',
  '/bitboxAddressRecovery',
  '/debugAuth',
};

/// Whether [loc] resolves to one of the [kGateLocations] gates. Compares the
/// path only, so a query string cannot defeat the check.
bool isGateLocation(String loc) => kGateLocations.contains(Uri.parse(loc).path);

/// Pure boot/lock routing decision, evaluated on every HomeBloc / PinAuthCubit
/// emission.
///
/// The gate ladder is evaluated top to bottom, so a restore can only ever be
/// returned by the final branch — after `!isPinVerified` has already diverted
/// to the PIN gate. A [BootNavRestore] therefore never re-enters a gate route
/// and never bypasses the PIN gate.
BootNavAction resolveBootNavigation({
  required bool isLoadingWallet,
  required bool softwareTermsAccepted,
  required bool hasWallet,
  required bool onboardingCompleted,
  required bool isPinSetup,
  required bool isPinVerified,
  required bool bitboxAddressRecoveryNeeded,
  required bool walletLoaded,
  required String currentLocation,
  required String? resumeLocation,
}) {
  if (isLoadingWallet) return const BootNavWaitForLoad();
  if (!softwareTermsAccepted) return const BootNavGoNamed(AppRoutes.home);
  if (!hasWallet) return const BootNavGoNamed(OnboardingRoutes.welcome);
  if (!onboardingCompleted) {
    return const BootNavGoNamed(OnboardingRoutes.completed);
  }
  if (!isPinSetup) return const BootNavGoNamed(PinRoutes.setup);
  if (!isPinVerified) return const BootNavGoNamed(PinRoutes.verify);
  if (bitboxAddressRecoveryNeeded) {
    // A BitBox wallet was persisted with an empty/invalid address — divert to
    // the re-pairing recovery flow instead of loading it into the dashboard
    // (which would crash the build via `EthereumAddress.fromHex("")`).
    return const BootNavGoNamed(AppRoutes.bitboxAddressRecovery);
  }
  if (!walletLoaded) return const BootNavLoadWallet();

  // All gates passed.
  if (!isGateLocation(currentLocation)) return const BootNavStay();
  if (resumeLocation != null && !isGateLocation(resumeLocation)) {
    return BootNavRestore(resumeLocation);
  }
  return const BootNavGoNamed(AppRoutes.dashboard);
}
