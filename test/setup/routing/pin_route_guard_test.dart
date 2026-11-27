import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/pin/bloc/auth/pin_auth_cubit.dart';
import 'package:realunit_wallet/screens/pin/verify_pin_page.dart';
import 'package:realunit_wallet/setup/routing/boot_navigation.dart';
import 'package:realunit_wallet/setup/routing/pin_route_guard.dart';
import 'package:realunit_wallet/setup/routing/referral_pending_code.dart';
import 'package:realunit_wallet/setup/routing/routes/app_link_entry.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/setup/routing/routes/pin_routes.dart';
import 'package:realunit_wallet/setup/routing/routes/settings_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockPinAuthCubit extends Mock implements PinAuthCubit {}

class _MockHomeBloc extends Mock implements HomeBloc {}

const _locations = {
  AppRoutes.home: '/home',
  AppRoutes.dashboard: '/dashboard',
  AppRoutes.kyc: '/kyc',
  AppRoutes.updateRequired: '/updateRequired',
  AppRoutes.receive: '/receive',
  SettingsRoutes.settings: '/settings',
  SettingsRoutes.seed: '/settings/seed',
  SettingsRoutes.changePin: '/settings/security/changePin',
  PinRoutes.gate: '/pinGate',
  PinRoutes.setup: '/setupPin',
  PinRoutes.verify: '/verifyPin',
};

String _locationOf(String name) => _locations[name]!;

void main() {
  group('resolvePinRouteGuard', () {
    String? decide(
      String path, {
      bool isLocked = false,
      bool isPinSetup = true,
      String currentLocation = '/dashboard',
      String? freshPinRoute,
    }) => resolvePinRouteGuard(
      path: path,
      currentLocation: currentLocation,
      locationOf: _locationOf,
      isLocked: isLocked,
      isPinSetup: isPinSetup,
      freshPinRoute: freshPinRoute,
    );

    test('a locked app sends every page to the PIN prompt', () {
      for (final path in _locations.values.where((p) => p != '/verifyPin')) {
        expect(decide(path, isLocked: true), '/verifyPin', reason: path);
      }
      expect(decide('/verifyPin', isLocked: true), isNull);
    });

    test('a locked app keeps a PIN prompt that is already showing', () {
      expect(
        decide('/settings', isLocked: true, currentLocation: '/verifyPin'),
        appLinkUrl,
      );
    });

    test('the PIN setup opens only while no PIN is set', () {
      expect(decide('/setupPin', isPinSetup: false), isNull);
      expect(decide('/setupPin'), appLinkUrl);
    });

    test('a protected route opens only with its own grant', () {
      expect(decide('/settings/seed'), appLinkUrl);
      expect(decide('/settings/seed', freshPinRoute: SettingsRoutes.seed), isNull);
      expect(decide('/settings/seed', freshPinRoute: SettingsRoutes.changePin), appLinkUrl);
      expect(decide('/settings/security/changePin'), appLinkUrl);
      expect(
        decide('/settings/security/changePin', freshPinRoute: SettingsRoutes.changePin),
        isNull,
      );
    });

    test('ordinary pages open while unlocked', () {
      for (final path in ['/home', '/dashboard', '/settings', '/kyc', '/updateRequired']) {
        expect(decide(path), isNull, reason: path);
      }
    });
  });

  test('isAppLocked needs a set PIN, no PIN entry and a wallet', () {
    expect(isAppLocked(isPinSetup: true, isPinVerified: false, hasWallet: () => true), isTrue);
    expect(isAppLocked(isPinSetup: true, isPinVerified: true, hasWallet: () => true), isFalse);
    expect(isAppLocked(isPinSetup: false, isPinVerified: false, hasWallet: () => true), isFalse);
    expect(isAppLocked(isPinSetup: true, isPinVerified: false, hasWallet: () => false), isFalse);
  });

  group('router with the PIN check', () {
    late _MockPinAuthCubit pinAuthCubit;
    late _MockHomeBloc homeBloc;
    var pinSetup = true;
    var pinVerified = true;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await clearPendingReferralCode();
      clearFreshPinGrant();
      pinSetup = true;
      pinVerified = true;
      pinAuthCubit = _MockPinAuthCubit();
      homeBloc = _MockHomeBloc();
      when(() => pinAuthCubit.state).thenAnswer(
        (_) => PinAuthState(isPinSetup: pinSetup, isPinVerified: pinVerified),
      );
      when(() => homeBloc.state).thenReturn(const HomeState(hasWallet: true));
      GetIt.instance
        ..registerSingleton<PinAuthCubit>(pinAuthCubit)
        ..registerSingleton<HomeBloc>(homeBloc);
    });

    tearDown(() async {
      clearFreshPinGrant();
      await GetIt.instance.reset();
    });

    Widget page(String key, {List<Widget> actions = const []}) => Scaffold(
      body: Column(
        children: [
          Text(key, key: Key(key)),
          ...actions,
        ],
      ),
    );

    Widget openSeedButton() => Builder(
      builder: (context) => TextButton(
        key: const Key('openSeed'),
        onPressed: () => pushAfterFreshPin(context, routeName: SettingsRoutes.seed),
        child: const Text('seed'),
      ),
    );

    Future<GoRouter> pump(WidgetTester tester, {String initial = '/dashboard'}) async {
      late final GoRouter router;
      router = GoRouter(
        initialLocation: initial,
        redirect: (context, state) => appRouterRedirect(state, router),
        onException: appLinkOnException,
        routes: [
          GoRoute(name: AppRoutes.home, path: '/home', builder: (_, _) => page('home')),
          GoRoute(
            name: AppRoutes.dashboard,
            path: '/dashboard',
            builder: (_, _) => page('dashboard'),
          ),
          GoRoute(name: AppRoutes.kyc, path: '/kyc', builder: (_, _) => page('kyc')),
          GoRoute(name: AppRoutes.receive, path: '/receive', builder: (_, _) => page('receive')),
          GoRoute(
            name: AppRoutes.updateRequired,
            path: '/updateRequired',
            builder: (_, _) => page('updateRequired', actions: [openSeedButton()]),
          ),
          GoRoute(
            name: PinRoutes.gate,
            path: '/pinGate',
            builder: (_, state) {
              final params = state.extra! as VerifyPinParams;
              return page(
                'pinGate',
                actions: [
                  TextButton(
                    key: const Key('pinEntered'),
                    onPressed: params.onAuthenticated,
                    child: const Text('ok'),
                  ),
                ],
              );
            },
          ),
          GoRoute(name: PinRoutes.setup, path: '/setupPin', builder: (_, _) => page('setupPin')),
          GoRoute(
            name: PinRoutes.verify,
            path: '/verifyPin',
            builder: (_, _) => page('verifyPin'),
          ),
          GoRoute(
            name: SettingsRoutes.settings,
            path: '/settings',
            builder: (_, _) => page('settings', actions: [openSeedButton()]),
            routes: [
              GoRoute(
                name: SettingsRoutes.seed,
                path: 'seed',
                builder: (_, _) => page('seed'),
              ),
              GoRoute(
                name: SettingsRoutes.changePin,
                path: 'security/changePin',
                builder: (_, _) => page('changePin'),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      return router;
    }

    Finder shows(String key) => find.byKey(Key(key));

    Future<void> enterPinForSeed(WidgetTester tester) async {
      await tester.tap(shows('openSeed'));
      await tester.pumpAndSettle();
      expect(shows('pinGate'), findsOneWidget);
      await tester.tap(shows('pinEntered'));
      await tester.pumpAndSettle();
    }

    void apply(GoRouter router, BootNavAction action) => applyBootNavAction(
      action,
      router,
      onLoadWallet: () {},
      onClearResume: () {},
    );

    testWidgets('the recovery phrase opens after the PIN gate', (tester) async {
      final router = await pump(tester, initial: '/settings');

      await enterPinForSeed(tester);

      expect(shows('seed'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(shows('settings'), findsOneWidget);
    });

    testWidgets('the recovery phrase asks for the PIN again after it was closed', (tester) async {
      final router = await pump(tester, initial: '/settings');
      await enterPinForSeed(tester);
      router.pop();
      await tester.pumpAndSettle();

      unawaited(router.pushNamed(SettingsRoutes.seed));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(shows('settings'), findsOneWidget);
      expect(shows('seed'), findsNothing);
    });

    testWidgets('a direct navigation to a protected route keeps the current screen', (
      tester,
    ) async {
      final router = await pump(tester, initial: '/settings');

      unawaited(router.pushNamed(SettingsRoutes.seed));
      await tester.pumpAndSettle();
      router.goNamed(SettingsRoutes.changePin);
      await tester.pumpAndSettle();
      router.goNamed(PinRoutes.setup);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(shows('settings'), findsOneWidget);
      expect(router.canPop(), isFalse);
    });

    testWidgets('a locked app shows the PIN prompt for any page and only once', (tester) async {
      final router = await pump(tester, initial: '/settings');
      pinVerified = false;

      unawaited(router.pushNamed(AppRoutes.dashboard));
      await tester.pumpAndSettle();
      expect(shows('verifyPin'), findsOneWidget);
      expect(shows('dashboard'), findsNothing);

      unawaited(router.pushNamed(SettingsRoutes.seed));
      await tester.pumpAndSettle();
      router.go('/settings');
      await tester.pumpAndSettle();

      expect(shows('verifyPin'), findsOneWidget);
      expect(shows('seed'), findsNothing);
      expect(shows('dashboard'), findsNothing);
    });

    testWidgets('a trailing slash does not get past the check', (tester) async {
      final router = await pump(tester, initial: '/settings');

      router.go('/settings/seed/');
      await tester.pumpAndSettle();
      router.go('/setupPin/');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(shows('settings'), findsOneWidget);
      expect(shows('seed'), findsNothing);
      expect(shows('setupPin'), findsNothing);
    });

    testWidgets('app start while locked opens the PIN prompt first', (tester) async {
      pinVerified = false;

      await pump(tester, initial: '/home');

      expect(shows('verifyPin'), findsOneWidget);
      expect(shows('home'), findsNothing);
    });

    testWidgets('app start of a device with a PIN but no wallet runs the onboarding', (
      tester,
    ) async {
      pinVerified = false;
      when(() => homeBloc.state).thenReturn(const HomeState());

      await pump(tester, initial: '/home');

      expect(shows('home'), findsOneWidget);
    });

    testWidgets('lock on return and unlock restore the screen the user was on', (tester) async {
      final router = await pump(tester, initial: '/dashboard');
      unawaited(router.pushNamed(SettingsRoutes.settings));
      await tester.pumpAndSettle();

      pinVerified = false;
      apply(router, const BootNavGoNamed(PinRoutes.verify));
      await tester.pumpAndSettle();
      expect(shows('verifyPin'), findsOneWidget);

      pinVerified = true;
      apply(router, const BootNavRestore('/settings'));
      await tester.pumpAndSettle();
      expect(shows('settings'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(shows('dashboard'), findsOneWidget);
    });

    testWidgets('the onboarding without a PIN reaches the PIN setup', (tester) async {
      pinSetup = false;
      pinVerified = false;
      final router = await pump(tester, initial: '/home');

      apply(router, const BootNavGoNamed(PinRoutes.setup));
      await tester.pumpAndSettle();
      expect(shows('setupPin'), findsOneWidget);

      pinSetup = true;
      pinVerified = true;
      router.goNamed(AppRoutes.dashboard);
      await tester.pumpAndSettle();
      expect(shows('dashboard'), findsOneWidget);
    });

    testWidgets('the KYC flow survives a lock and returns after the PIN', (tester) async {
      final router = await pump(tester, initial: '/dashboard');
      unawaited(router.pushNamed(AppRoutes.kyc));
      await tester.pumpAndSettle();
      expect(shows('kyc'), findsOneWidget);

      pinVerified = false;
      apply(router, const BootNavGoNamed(PinRoutes.verify));
      await tester.pumpAndSettle();
      expect(shows('verifyPin'), findsOneWidget);

      pinVerified = true;
      apply(router, const BootNavRestore('/kyc'));
      await tester.pumpAndSettle();
      expect(shows('kyc'), findsOneWidget);
    });

    testWidgets('the required update still offers the recovery phrase and receive', (
      tester,
    ) async {
      final router = await pump(tester, initial: '/dashboard');
      apply(router, const BootNavGoNamed(AppRoutes.updateRequired));
      await tester.pumpAndSettle();
      expect(shows('updateRequired'), findsOneWidget);

      await enterPinForSeed(tester);
      expect(shows('seed'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();

      unawaited(router.pushNamed(AppRoutes.receive));
      await tester.pumpAndSettle();
      expect(shows('receive'), findsOneWidget);
    });

    testWidgets('an invite link keeps the PIN prompt in place', (tester) async {
      pinVerified = false;
      final router = await pump(tester, initial: '/verifyPin');

      router.go('realunit-wallet://invite/settings');
      await tester.pumpAndSettle();

      expect(shows('verifyPin'), findsOneWidget);
      expect(shows('settings'), findsNothing);
    });
  });
}
