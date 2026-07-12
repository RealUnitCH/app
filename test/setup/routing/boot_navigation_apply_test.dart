import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/setup/routing/boot_navigation.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/setup/routing/routes/pin_routes.dart';

// Drives the real `_navigate` wiring — `resolveBootNavigation` + the go_router
// side effect `applyBootNavAction` — against a real [GoRouter]. This is the seam
// the pure-function table and the cubit tests can't reach: it proves the
// decision is actually enacted on a router, and that a resume of an
// `extra`-required route lands on the dashboard WITHOUT building (and crashing
// on) that route. Pumping the full `WalletApp` is impractical (it depends on the
// whole DI graph + the global router building real, service-backed pages), so we
// exercise the smallest faithful seam instead.
void main() {
  // Only the routes this seam touches. `/buyPaymentDetails` mirrors the real
  // builder's non-nullable `extra` cast, so building it from a bare path throws
  // — exactly the crash the restore allowlist must prevent.
  GoRouter buildRouter() => GoRouter(
    initialLocation: '/verifyPin',
    routes: [
      GoRoute(
        name: PinRoutes.verify,
        path: '/verifyPin',
        builder: (_, _) => const Text('verify'),
      ),
      GoRoute(
        name: AppRoutes.dashboard,
        path: '/dashboard',
        builder: (_, _) => const Text('dashboard'),
      ),
      GoRoute(
        name: AppRoutes.kyc,
        path: '/kyc',
        builder: (_, _) => const Text('kyc'),
      ),
      GoRoute(
        name: AppRoutes.buyPaymentDetails,
        path: '/buyPaymentDetails',
        builder: (_, state) => Text('buy ${state.extra as Object}'),
      ),
    ],
  );

  // Fully-passed post-gate input: the router is on the PIN gate right after a
  // re-lock, so a captured non-gate route can be restored.
  BootNavAction resolveAfterRelock(String? resumeLocation) => resolveBootNavigation(
    isLoadingWallet: false,
    softwareTermsAccepted: true,
    hasWallet: true,
    onboardingCompleted: true,
    isPinSetup: true,
    isPinVerified: true,
    bitboxAddressRecoveryNeeded: false,
    walletLoaded: true,
    currentLocation: '/verifyPin',
    resumeLocation: resumeLocation,
  );

  String locationOf(GoRouter router) => router.routerDelegate.currentConfiguration.uri.toString();

  testWidgets('re-lock -> PIN -> restore lands on the captured /kyc route', (
    tester,
  ) async {
    final router = buildRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    var cleared = false;
    applyBootNavAction(
      resolveAfterRelock('/kyc'),
      router,
      onLoadWallet: () {},
      onClearResume: () => cleared = true,
    );
    await tester.pumpAndSettle();

    expect(find.text('kyc'), findsOneWidget);
    expect(locationOf(router), '/kyc');
    expect(cleared, isTrue);
  });

  testWidgets(
    'resuming an extra-required route lands on /dashboard without throwing',
    (tester) async {
      final router = buildRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final action = resolveAfterRelock('/buyPaymentDetails');
      // Fail-closed: not on the allowlist -> dashboard, never the crashing route.
      expect((action as BootNavGoNamed).routeName, AppRoutes.dashboard);

      applyBootNavAction(
        action,
        router,
        onLoadWallet: () {},
        onClearResume: () {},
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('dashboard'), findsOneWidget);
      expect(locationOf(router), '/dashboard');
    },
  );

  testWidgets(
    'premise guard: restoring /buyPaymentDetails from a bare path really throws',
    (tester) async {
      final router = buildRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Proves the crash the allowlist prevents is real: navigating to the
      // extra-required route without `extra` surfaces an exception.
      router.go('/buyPaymentDetails');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNotNull);
    },
  );

  testWidgets(
    'effectiveLocation reports a pushed route where the raw uri stays on the base',
    (tester) async {
      final router = buildRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      router.go('/dashboard');
      await tester.pumpAndSettle();
      expect(effectiveLocation(router.routerDelegate.currentConfiguration), '/dashboard');

      // The KYC flow is entered exactly like this: an imperative push on top
      // of the dashboard.
      unawaited(router.push('/kyc'));
      await tester.pumpAndSettle();

      // Premise guard for every effectiveLocation call site: the raw uri is
      // blind to the push — the helper is not.
      expect(locationOf(router), '/dashboard');
      expect(effectiveLocation(router.routerDelegate.currentConfiguration), '/kyc');
    },
  );
}
