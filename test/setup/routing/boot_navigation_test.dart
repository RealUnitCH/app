import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/packages/utils/marketing_version.dart';
import 'package:realunit_wallet/setup/routing/boot_navigation.dart';
import 'package:realunit_wallet/setup/routing/router_config.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/setup/routing/routes/onboarding_routes.dart';
import 'package:realunit_wallet/setup/routing/routes/pin_routes.dart';

void main() {
  // The drift-pin group below constructs the real global GoRouter; initialize
  // the test binding up front, matching the repo convention for plain-test
  // files that touch framework globals.
  TestWidgetsFlutterBinding.ensureInitialized();

  // A fully-passed, steady-state input where the user sits on a non-gate route
  // (/kyc). Individual tests flip exactly one field to exercise one branch.
  BootNavAction resolve({
    bool isLoadingWallet = false,
    bool softwareTermsAccepted = true,
    bool hasWallet = true,
    bool onboardingCompleted = true,
    bool isPinSetup = true,
    bool isPinVerified = true,
    bool bitboxAddressRecoveryNeeded = false,
    bool walletLoaded = true,
    String currentLocation = '/kyc',
    String? resumeLocation,
    ClientPolicySeverity clientPolicySeverity = ClientPolicySeverity.none,
  }) => resolveBootNavigation(
    isLoadingWallet: isLoadingWallet,
    softwareTermsAccepted: softwareTermsAccepted,
    hasWallet: hasWallet,
    onboardingCompleted: onboardingCompleted,
    isPinSetup: isPinSetup,
    isPinVerified: isPinVerified,
    bitboxAddressRecoveryNeeded: bitboxAddressRecoveryNeeded,
    walletLoaded: walletLoaded,
    currentLocation: currentLocation,
    resumeLocation: resumeLocation,
    clientPolicySeverity: clientPolicySeverity,
  );

  BootNavAction hard({
    bool isLoadingWallet = false,
    bool softwareTermsAccepted = true,
    bool hasWallet = true,
    bool onboardingCompleted = true,
    bool isPinSetup = true,
    bool isPinVerified = true,
    bool bitboxAddressRecoveryNeeded = false,
    bool walletLoaded = true,
    String currentLocation = '/kyc',
    String? resumeLocation,
  }) => resolve(
    isLoadingWallet: isLoadingWallet,
    softwareTermsAccepted: softwareTermsAccepted,
    hasWallet: hasWallet,
    onboardingCompleted: onboardingCompleted,
    isPinSetup: isPinSetup,
    isPinVerified: isPinVerified,
    bitboxAddressRecoveryNeeded: bitboxAddressRecoveryNeeded,
    walletLoaded: walletLoaded,
    currentLocation: currentLocation,
    resumeLocation: resumeLocation,
    clientPolicySeverity: ClientPolicySeverity.hard,
  );

  group('resolveBootNavigation gate ladder', () {
    test('isLoadingWallet short-circuits to wait, ignoring everything else', () {
      expect(
        resolve(
          isLoadingWallet: true,
          softwareTermsAccepted: false,
          resumeLocation: '/kyc',
        ),
        isA<BootNavWaitForLoad>(),
      );
    });

    test('missing software terms -> home', () {
      final action = resolve(softwareTermsAccepted: false);
      expect((action as BootNavGoNamed).routeName, AppRoutes.home);
    });

    test('no wallet -> welcome', () {
      final action = resolve(hasWallet: false);
      expect((action as BootNavGoNamed).routeName, OnboardingRoutes.welcome);
    });

    test('no wallet + soft still welcome', () {
      final action = resolve(
        hasWallet: false,
        clientPolicySeverity: ClientPolicySeverity.soft,
      );
      expect((action as BootNavGoNamed).routeName, OnboardingRoutes.welcome);
    });

    test('onboarding not completed -> onboarding completed screen', () {
      final action = resolve(onboardingCompleted: false);
      expect((action as BootNavGoNamed).routeName, OnboardingRoutes.completed);
    });

    test('pin not set up -> setup pin', () {
      final action = resolve(isPinSetup: false);
      expect((action as BootNavGoNamed).routeName, PinRoutes.setup);
    });

    test('pin not verified -> verify pin', () {
      final action = resolve(isPinVerified: false);
      expect((action as BootNavGoNamed).routeName, PinRoutes.verify);
    });

    test('bitbox address recovery needed -> recovery flow', () {
      final action = resolve(bitboxAddressRecoveryNeeded: true);
      expect(
        (action as BootNavGoNamed).routeName,
        AppRoutes.bitboxAddressRecovery,
      );
    });

    test('wallet not loaded -> load wallet', () {
      expect(resolve(walletLoaded: false), isA<BootNavLoadWallet>());
    });
  });

  group('resolveBootNavigation gate precedence over restore (security)', () {
    test(
      'an un-verified PIN wins over a pending restore: never bypasses the gate',
      () {
        // The router is on the PIN gate and a restorable /kyc is captured, but
        // isPinVerified is false -> we MUST go to the PIN gate, never restore.
        final action = resolve(
          isPinVerified: false,
          currentLocation: '/verifyPin',
          resumeLocation: '/kyc',
        );
        expect((action as BootNavGoNamed).routeName, PinRoutes.verify);
      },
    );
  });

  group('resolveBootNavigation post-gate landing', () {
    test('already on a valid non-gate route -> stay put (never yank)', () {
      // Even with a stale capture present, an active non-gate route is kept.
      expect(
        resolve(currentLocation: '/kyc', resumeLocation: '/settings'),
        isA<BootNavStay>(),
      );
    });

    test('on the dashboard steady state -> stay put', () {
      expect(resolve(currentLocation: '/dashboard'), isA<BootNavStay>());
    });

    test('core scenario: relocked on the PIN gate, restore the captured /kyc', () {
      final action = resolve(
        currentLocation: '/verifyPin',
        resumeLocation: '/kyc',
      );
      expect((action as BootNavRestore).location, '/kyc');
    });

    test('on a gate route with no capture -> dashboard fallback', () {
      final action = resolve(currentLocation: '/verifyPin', resumeLocation: null);
      expect((action as BootNavGoNamed).routeName, AppRoutes.dashboard);
    });

    test('a gate resume location is NOT restored -> dashboard fallback', () {
      // The captured route is itself a gate (e.g. /setupPin): restoring it
      // would be pointless / unsafe, so fall back to the dashboard.
      final action = resolve(
        currentLocation: '/verifyPin',
        resumeLocation: '/setupPin',
      );
      expect((action as BootNavGoNamed).routeName, AppRoutes.dashboard);
    });

    test('restore preserves a resume path that carries a query string', () {
      final action = resolve(
        currentLocation: '/verifyPin',
        resumeLocation: '/kyc?context=buy',
      );
      expect((action as BootNavRestore).location, '/kyc?context=buy');
    });

    test('an extra-required resume route is NOT restored -> dashboard', () {
      // `/buyPaymentDetails` rebuilds via `state.extra as BuyPaymentDetailsParams`
      // (non-nullable): restoring it from a bare path would crash, so it is not
      // on the allowlist and falls back to the dashboard (fail-closed).
      final action = resolve(
        currentLocation: '/verifyPin',
        resumeLocation: '/buyPaymentDetails',
      );
      expect((action as BootNavGoNamed).routeName, AppRoutes.dashboard);
    });

    test('a PIN-gated settings subroute is NOT restored -> dashboard', () {
      // `/settings/seed` sits behind a secondary PIN gate; exact-path matching
      // (`/settings/seed` != `/settings`) keeps it off the allowlist.
      final action = resolve(
        currentLocation: '/verifyPin',
        resumeLocation: '/settings/seed',
      );
      expect((action as BootNavGoNamed).routeName, AppRoutes.dashboard);
    });
  });

  group('hard H1-H20', () {
    test('H1 isLoadingWallet true → WaitForLoad', () {
      expect(hard(isLoadingWallet: true), isA<BootNavWaitForLoad>());
    });

    test('H2 softwareTermsAccepted false → GoNamed home', () {
      final action = hard(softwareTermsAccepted: false);
      expect((action as BootNavGoNamed).routeName, AppRoutes.home);
    });

    test('H3 hasWallet false → GoNamed updateRequired', () {
      final action = hard(hasWallet: false);
      expect((action as BootNavGoNamed).routeName, AppRoutes.updateRequired);
    });

    test('H4 onboardingCompleted false → GoNamed completed', () {
      final action = hard(onboardingCompleted: false);
      expect((action as BootNavGoNamed).routeName, OnboardingRoutes.completed);
    });

    test('H5 isPinSetup false → GoNamed setup', () {
      final action = hard(isPinSetup: false);
      expect((action as BootNavGoNamed).routeName, PinRoutes.setup);
    });

    test('H6 isPinVerified false, resumeLocation /buy → GoNamed verify', () {
      final action = hard(isPinVerified: false, resumeLocation: '/buy');
      expect((action as BootNavGoNamed).routeName, PinRoutes.verify);
    });

    test(
      'H7b bitboxAddressRecoveryNeeded true, currentLocation /dashboard → GoNamed updateRequired',
      () {
        final action = hard(
          bitboxAddressRecoveryNeeded: true,
          currentLocation: '/dashboard',
        );
        expect((action as BootNavGoNamed).routeName, AppRoutes.updateRequired);
      },
    );

    test('H8 walletLoaded false → LoadWallet', () {
      expect(hard(walletLoaded: false), isA<BootNavLoadWallet>());
    });

    test('H9 currentLocation /receive, resumeLocation /buy → Stay', () {
      expect(
        hard(currentLocation: '/receive', resumeLocation: '/buy'),
        isA<BootNavStay>(),
      );
    });

    test(
      'H10 currentLocation /settings/seed, resumeLocation /dashboard → Stay',
      () {
        expect(
          hard(
            currentLocation: '/settings/seed',
            resumeLocation: '/dashboard',
          ),
          isA<BootNavStay>(),
        );
      },
    );

    test('H11 currentLocation /pinGate, resumeLocation /kyc → Stay', () {
      expect(
        hard(currentLocation: '/pinGate', resumeLocation: '/kyc'),
        isA<BootNavStay>(),
      );
    });

    test(
      'H12 currentLocation /updateRequired, resumeLocation /dashboard → Stay',
      () {
        expect(
          hard(
            currentLocation: '/updateRequired',
            resumeLocation: '/dashboard',
          ),
          isA<BootNavStay>(),
        );
      },
    );

    test(
      'H13 currentLocation /dashboard, resumeLocation /dashboard → GoNamed updateRequired',
      () {
        final action = hard(
          currentLocation: '/dashboard',
          resumeLocation: '/dashboard',
        );
        expect((action as BootNavGoNamed).routeName, AppRoutes.updateRequired);
      },
    );

    test('H14 /buy → updateRequired', () {
      final action = hard(currentLocation: '/buy');
      expect((action as BootNavGoNamed).routeName, AppRoutes.updateRequired);
    });

    test('H15 /sell → updateRequired', () {
      final action = hard(currentLocation: '/sell');
      expect((action as BootNavGoNamed).routeName, AppRoutes.updateRequired);
    });

    test('H16 /kyc → updateRequired', () {
      final action = hard(currentLocation: '/kyc');
      expect((action as BootNavGoNamed).routeName, AppRoutes.updateRequired);
    });

    test('H17 /support → updateRequired', () {
      final action = hard(currentLocation: '/support');
      expect((action as BootNavGoNamed).routeName, AppRoutes.updateRequired);
    });

    test('H18 /settings → updateRequired', () {
      final action = hard(currentLocation: '/settings');
      expect((action as BootNavGoNamed).routeName, AppRoutes.updateRequired);
    });

    test(
      'H19 currentLocation /verifyPin, resumeLocation /buy (all passed) → GoNamed updateRequired (not Restore)',
      () {
        final action = hard(
          currentLocation: '/verifyPin',
          resumeLocation: '/buy',
        );
        expect(action, isNot(isA<BootNavRestore>()));
        expect((action as BootNavGoNamed).routeName, AppRoutes.updateRequired);
      },
    );

    test('H20 currentLocation /home → GoNamed updateRequired', () {
      final action = hard(currentLocation: '/home');
      expect((action as BootNavGoNamed).routeName, AppRoutes.updateRequired);
    });
  });

  group('isGateLocation', () {
    for (final loc in gateLocations) {
      test('$loc is a gate', () => expect(isGateLocation(loc), isTrue));
    }

    test('a non-gate app route is not a gate', () {
      expect(isGateLocation('/kyc'), isFalse);
      expect(isGateLocation('/dashboard'), isFalse);
      expect(isGateLocation('/settings/security'), isFalse);
    });

    test('a query string does not defeat the gate check', () {
      expect(isGateLocation('/verifyPin?x=1'), isTrue);
    });

    test('resumeCaptureFor maps gates to null and keeps in-flight routes', () {
      expect(resumeCaptureFor('/verifyPin'), isNull);
      expect(resumeCaptureFor('/pinGate'), isNull);
      expect(resumeCaptureFor('/kyc'), '/kyc');
      expect(resumeCaptureFor('/kyc?context=buy'), '/kyc?context=buy');
      expect(resumeCaptureFor(''), '');
    });

    test('a query string does not turn a non-gate into a gate', () {
      expect(isGateLocation('/kyc?context=buy'), isFalse);
    });
  });

  group('isRestorableLocation', () {
    for (final loc in restorableLocations) {
      test(
        '$loc is restorable',
        () => expect(isRestorableLocation(loc), isTrue),
      );
    }

    test('an extra-required route is not restorable', () {
      expect(isRestorableLocation('/buyPaymentDetails'), isFalse);
      expect(isRestorableLocation('/sellBitbox'), isFalse);
      expect(isRestorableLocation('/legalDocument'), isFalse);
      expect(isRestorableLocation('/webView'), isFalse);
    });

    test('a PIN-gated / sensitive subroute is not restorable', () {
      expect(isRestorableLocation('/settings/seed'), isFalse);
      expect(isRestorableLocation('/settings/security'), isFalse);
      expect(isRestorableLocation('/settings/security/changePin'), isFalse);
    });

    test('a gate route is not restorable', () {
      expect(isRestorableLocation('/verifyPin'), isFalse);
      expect(isRestorableLocation('/home'), isFalse);
    });

    test('a query string does not defeat the allowlist match', () {
      expect(isRestorableLocation('/kyc?context=buy'), isTrue);
    });
  });

  group('drift pin against the real route table', () {
    // Both sets duplicate path literals from router_config.dart. A path rename
    // there would otherwise drift silently: an unrecognized gate strands the
    // user on the gate screen (BootNavStay instead of the dashboard fallback),
    // an unrecognized restorable route silently degrades to the dashboard.
    Set<String> collectPaths(List<RouteBase> routes, String prefix) {
      final paths = <String>{};
      for (final route in routes) {
        var next = prefix;
        if (route is GoRoute) {
          next = route.path.startsWith('/')
              ? route.path
              : '${prefix == '/' ? '' : prefix}/${route.path}';
          paths.add(next);
        }
        paths.addAll(collectPaths(route.routes, next));
      }
      return paths;
    }

    test('every gate and restorable location is a real route path', () {
      // Constructing GoRouter never invokes page builders, so walking the real
      // routerConfig needs neither DI nor pumpWidget.
      final realPaths = collectPaths(routerConfig.configuration.routes, '');

      expect(gateLocations.difference(realPaths), isEmpty);
      expect(restorableLocations.difference(realPaths), isEmpty);
    });
  });
}
