/// Locations that are boot/lock gates: `_navigate` re-derives them from state
/// and must never treat one as an in-flight route to restore. What *is*
/// restorable is governed by the `restorableLocations` allowlist in
/// `boot_navigation.dart` — not by "anything that is not a gate".
const Set<String> gateLocations = {
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
  '/updateRequired',
};

/// Whether [loc] resolves to one of the [gateLocations] gates. Compares the
/// path only, so a query string cannot defeat the check.
bool isGateLocation(String loc) => gateLocations.contains(Uri.parse(loc).path);
