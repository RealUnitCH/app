import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/setup/routing/routes/onboarding_routes.dart';
import 'package:realunit_wallet/setup/routing/routes/pin_routes.dart';

/// The outcome of the boot/lock navigation decision (see
/// [resolveBootNavigation]) driven by `main.dart`'s `_navigate`. The decision
/// itself is `getIt`-free so the whole gate ladder can be unit-tested
/// exhaustively; [applyBootNavAction] below performs the go_router side effect.
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

/// Locations that are boot/lock gates: `_navigate` re-derives them from state
/// and must never treat one as an in-flight route to restore. What *is*
/// restorable is governed by the [kRestorableLocations] allowlist below — not
/// by "anything that is not a gate".
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

/// Non-gate locations safe to restore after a resume / re-lock: they rebuild
/// from a bare path (no required `extra`) and sit behind no secondary PIN gate.
/// Fail-closed — anything not listed falls back to the dashboard (the pre-fix
/// behaviour), so a newly added route can never silently become restorable (and
/// crash on a missing `extra`) or surface a PIN-gated screen. Matched by exact
/// path: `/settings/seed` != `/settings`, `/buyPaymentDetails` != `/buy`.
const Set<String> kRestorableLocations = {
  '/kyc',
  '/dashboard',
  '/buy',
  '/sell',
  '/receive',
  '/settings',
  '/support',
};

/// Whether [loc]'s path is in the [kRestorableLocations] allowlist (query
/// string ignored).
bool isRestorableLocation(String loc) => kRestorableLocations.contains(Uri.parse(loc).path);

/// Pure boot/lock routing decision, evaluated on every HomeBloc / PinAuthCubit
/// emission.
///
/// The gate ladder is evaluated top to bottom, so a restore can only ever be
/// returned by the final branch — after `!isPinVerified` has already diverted
/// to the PIN gate. A [BootNavRestore] is additionally limited to the
/// [kRestorableLocations] allowlist, so it never re-enters a gate route, never
/// bypasses the PIN gate, and never targets a route that needs `extra`.
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
  if (resumeLocation != null && isRestorableLocation(resumeLocation)) {
    return BootNavRestore(resumeLocation);
  }
  return const BootNavGoNamed(AppRoutes.dashboard);
}

/// Executes a [resolveBootNavigation] decision against [router]. Split out from
/// `main.dart`'s `_navigate` so the routing side effects can be driven against a
/// real [GoRouter] in a widget test (the decision itself is covered by the pure
/// table). [onLoadWallet] triggers the wallet load; [onClearResume] drops the
/// captured resume location once it is spent.
void applyBootNavAction(
  BootNavAction action,
  GoRouter router, {
  required void Function() onLoadWallet,
  required void Function() onClearResume,
}) {
  switch (action) {
    case BootNavWaitForLoad():
      return;
    case BootNavLoadWallet():
      // Wallet not loaded yet — trigger load and wait for the HomeBloc update.
      onLoadWallet();
      return;
    case BootNavGoNamed(:final routeName):
      // Reaching the dashboard is the final landing — drop any stale resume
      // capture so a later benign emission can't bounce the user around.
      if (routeName == AppRoutes.dashboard) onClearResume();
      router.goNamed(routeName);
      return;
    case BootNavRestore(:final location):
      // Return to the in-flight route the user was on before the re-lock,
      // reached only after the PIN gate above has already passed.
      onClearResume();
      router.go(location);
      return;
    case BootNavStay():
      // Already on a valid non-gate route — discard any stale capture.
      onClearResume();
      return;
  }
}
