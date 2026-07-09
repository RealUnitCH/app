import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/setup/routing/routes/app_link_entry.dart';

void main() {
  // A minimal router wired to the *production* [appLinkSchemeRedirect], exactly
  // as router_config.dart wires it (current location read from the router's own
  // delegate). `/home` is the normal cold-start entry; `/dashboard` and
  // `/settings` stand in for arbitrary in-app routes a warm resume must preserve.
  GoRouter buildRouter({String initialLocation = '/home'}) {
    late final GoRouter router;
    router = GoRouter(
      initialLocation: initialLocation,
      redirect: (context, state) => appLinkSchemeRedirect(
        state,
        router.routerDelegate.currentConfiguration.uri.toString(),
      ),
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('HOME', key: Key('home'))),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (_, _) => const Scaffold(body: Text('DASH', key: Key('dashboard'))),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, _) => const Scaffold(body: Text('SET', key: Key('settings'))),
        ),
      ],
    );
    return router;
  }

  String currentPath(GoRouter router) => router.routerDelegate.currentConfiguration.uri.path;

  Future<GoRouter> pump(WidgetTester tester, {String initial = '/home'}) async {
    final router = buildRouter(initialLocation: initial);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  test('scheme constants', () {
    expect(appLinkScheme, 'realunit-wallet');
    expect(appLinkUrl, 'realunit-wallet://open');
    expect(appLinkColdStartLocation, '/home');
  });

  testWidgets('warm resume: a scheme open keeps the user on /dashboard', (
    tester,
  ) async {
    final router = await pump(tester);
    router.go('/dashboard');
    await tester.pumpAndSettle();
    expect(currentPath(router), '/dashboard');

    // The scheme open must NOT force any navigation — no jump to /home.
    router.go(appLinkUrl);
    await tester.pumpAndSettle();

    expect(currentPath(router), '/dashboard');
    expect(find.byKey(const Key('dashboard')), findsOneWidget);
    expect(find.byKey(const Key('home')), findsNothing);
  });

  testWidgets('warm resume: a scheme open keeps the user on any route', (
    tester,
  ) async {
    final router = await pump(tester);
    router.go('/settings');
    await tester.pumpAndSettle();
    expect(currentPath(router), '/settings');

    router.go(appLinkUrl);
    await tester.pumpAndSettle();

    expect(currentPath(router), '/settings');
    expect(find.byKey(const Key('settings')), findsOneWidget);
  });

  testWidgets('cold start on the scheme URL boots to the normal entry', (
    tester,
  ) async {
    // Simulates the OS delivering `realunit-wallet://open` as the initial route
    // on a fresh launch (no prior in-app route to preserve).
    final router = await pump(tester, initial: appLinkUrl);

    expect(currentPath(router), appLinkColdStartLocation);
    expect(find.byKey(const Key('home')), findsOneWidget);
  });

  testWidgets(
    'cold start on any scheme host/path boots without an error screen',
    (tester) async {
      for (final url in const [
        'realunit-wallet://',
        'realunit-wallet://open/foo?x=1',
        'realunit-wallet://anything',
      ]) {
        final router = await pump(tester, initial: url);
        expect(currentPath(router), appLinkColdStartLocation, reason: 'for $url');
        expect(
          find.byKey(const Key('home')),
          findsOneWidget,
          reason: 'for $url',
        );
      }
    },
  );

  testWidgets(
    'cold start on a crafted scheme URL to an auth path still boots to /home '
    '(PIN gate not bypassed)',
    (tester) async {
      // `realunit-wallet://dashboard` must not open the authenticated dashboard;
      // with no prior route it boots to /home and the real boot flow (PIN gate)
      // in main.dart runs.
      final router = await pump(tester, initial: 'realunit-wallet://dashboard');

      expect(currentPath(router), appLinkColdStartLocation);
      expect(find.byKey(const Key('dashboard')), findsNothing);
      expect(find.byKey(const Key('home')), findsOneWidget);
    },
  );

  testWidgets('in-app navigation is left untouched by the scheme redirect', (
    tester,
  ) async {
    final router = await pump(tester);

    router.go('/dashboard');
    await tester.pumpAndSettle();
    expect(currentPath(router), '/dashboard');
    expect(find.byKey(const Key('dashboard')), findsOneWidget);
  });
}
