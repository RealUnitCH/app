import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/settings_contact/settings_contact_page.dart';
import 'package:realunit_wallet/screens/web_view/web_view_page.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/setup/routing/routes/support_routes.dart';
import 'package:realunit_wallet/widgets/outlined_tile.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// Records every [launchUrl] call so each test can assert what the production
/// `onTap` requested without driving a real platform channel. Mirrors the
/// helper in test/packages/config/legal_documents_config_test.dart — kept
/// inline here because that helper is private to its file.
class _RecordingUrlLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  final List<({String url, LaunchOptions options})> calls = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    // The production code calls the modern [launchUrl] overload, but the
    // platform-interface contract requires this legacy method to exist.
    calls.add((url: url, options: const LaunchOptions()));
    return true;
  }

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    calls.add((url: url, options: options));
    return true;
  }

  @override
  Future<bool> supportsMode(PreferredLaunchMode mode) async => true;

  @override
  Future<bool> supportsCloseForMode(PreferredLaunchMode mode) async => false;
}

/// A placeholder destination so `pushNamed` resolves to a buildable route.
class _RoutePlaceholder extends StatelessWidget {
  const _RoutePlaceholder(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Scaffold(body: Text(label));
}

/// Wraps the page in a [GoRouter] that captures route pushes. Both
/// `SupportRoutes.support` and `AppRoutes.webView` are declared so every
/// tile's `onTap` resolves; the web-view route stashes its `extra` so tests
/// can assert on the [WebViewRouteParams] payload.
GoRouter _routerFor({
  List<String>? pushedRouteNames,
  List<WebViewRouteParams>? webParams,
}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const SettingsContactPage(),
      ),
      GoRoute(
        path: '/support',
        name: SupportRoutes.support,
        builder: (_, _) {
          pushedRouteNames?.add(SupportRoutes.support);
          return const _RoutePlaceholder('support');
        },
      ),
      GoRoute(
        path: '/web-view',
        name: AppRoutes.webView,
        builder: (_, state) {
          pushedRouteNames?.add(AppRoutes.webView);
          webParams?.add(state.extra! as WebViewRouteParams);
          return const _RoutePlaceholder('web');
        },
      ),
    ],
  );
}

Widget _harness(GoRouter router) {
  return MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
  );
}

/// Locates the [OutlinedTile] whose `subtitle` matches [subtitle]. Subtitles
/// are unique per tile on this page, which keeps the finders robust against
/// any future title-string tweak.
Finder _tileWithSubtitle(String subtitle) => find.byWidgetPredicate(
  (w) => w is OutlinedTile && w.subtitle == subtitle,
);

/// Locates the [OutlinedTile] that contains the given [icon] as its leading
/// widget. Used for tiles whose subtitle is i18n-localized and therefore not
/// a stable selector — currently only the Support tile.
Finder _tileWithIcon(IconData icon) => find.ancestor(
  of: find.byIcon(icon),
  matching: find.byType(OutlinedTile),
);

void main() {
  group('$SettingsContactPage', () {
    late _RecordingUrlLauncher launcher;
    late UrlLauncherPlatform originalLauncher;

    setUp(() {
      originalLauncher = UrlLauncherPlatform.instance;
      launcher = _RecordingUrlLauncher();
      UrlLauncherPlatform.instance = launcher;
    });

    tearDown(() {
      UrlLauncherPlatform.instance = originalLauncher;
    });

    testWidgets('renders without any DI / BlocProvider / Cubit setup', (tester) async {
      // PR #588's central contract: the page is a pure StatelessWidget and
      // does NOT depend on GetIt, SettingsContactCubit, or any backend call.
      // If a future change re-introduces a dependency, pumping the bare
      // MaterialApp.router below will throw and this test will catch it.
      final router = _routerFor();
      addTearDown(router.dispose);

      await tester.pumpWidget(_harness(router));

      expect(find.byType(SettingsContactPage), findsOneWidget);
      expect(tester.takeException(), isNull);
      // Tile topology is part of the contract: Support / Phone / Email /
      // Website (4 interactive tiles) + Imprint (1 informational tile).
      // A drift in this count signals a structural regression.
      expect(find.byType(OutlinedTile), findsNWidgets(5));
    });

    testWidgets('Support tile is unconditional (PR #588 behaviour contract)', (tester) async {
      // Before #588 the Support tile was gated on
      // UserCapabilitiesDto.supportAvailable. After #588 it must always
      // render — regardless of mail/auth/user state. The tile is identified
      // by its `Icons.support_agent_outlined` leading (hardcoded, locale-
      // independent) rather than by its localized title/subtitle, matching
      // the subtitle-based finder convention used by the other tile tests.
      final router = _routerFor();
      addTearDown(router.dispose);

      await tester.pumpWidget(_harness(router));

      expect(find.byIcon(Icons.support_agent_outlined), findsOneWidget);
      final supportTile = tester.widget<OutlinedTile>(
        _tileWithIcon(Icons.support_agent_outlined),
      );
      // The tile must be tappable — i.e. wired to the support route.
      expect(supportTile.onTap, isNotNull);
    });

    testWidgets('Support tile tap pushes SupportRoutes.support', (tester) async {
      final pushed = <String>[];
      final router = _routerFor(pushedRouteNames: pushed);
      addTearDown(router.dispose);

      await tester.pumpWidget(_harness(router));
      // Tap on the OutlinedTile that owns the support icon — consistent
      // with the subtitle-finder tap pattern used by the other tile tests.
      await tester.tap(_tileWithIcon(Icons.support_agent_outlined));
      await tester.pumpAndSettle();

      expect(launcher.calls, isEmpty);
      expect(pushed, [SupportRoutes.support]);
    });

    testWidgets('Phone tile shows +41 41 761 00 90 and launches tel: URI', (tester) async {
      final pushed = <String>[];
      final router = _routerFor(pushedRouteNames: pushed);
      addTearDown(router.dispose);

      await tester.pumpWidget(_harness(router));

      expect(find.text('+41 41 761 00 90'), findsOneWidget);

      await tester.tap(_tileWithSubtitle('+41 41 761 00 90'));
      await tester.pumpAndSettle();

      expect(launcher.calls, hasLength(1));
      // Number passed to launchUrl must be the dial-able form (no spaces).
      expect(launcher.calls.single.url, 'tel:+41417610090');
      // The phone tile must NOT also push a route — it hands off to the OS.
      expect(pushed, isEmpty);
    });

    testWidgets('Email tile shows info@realunit.ch and launches mailto: URI', (tester) async {
      final pushed = <String>[];
      final router = _routerFor(pushedRouteNames: pushed);
      addTearDown(router.dispose);

      await tester.pumpWidget(_harness(router));

      expect(find.text('info@realunit.ch'), findsOneWidget);

      await tester.tap(_tileWithSubtitle('info@realunit.ch'));
      await tester.pumpAndSettle();

      expect(launcher.calls, hasLength(1));
      expect(launcher.calls.single.url, 'mailto:info@realunit.ch');
      // The email tile must NOT also push a route — it hands off to the OS.
      expect(pushed, isEmpty);
    });

    testWidgets('Website tile pushes AppRoutes.webView with realunit.ch params', (tester) async {
      final pushed = <String>[];
      final webParams = <WebViewRouteParams>[];
      final router = _routerFor(
        pushedRouteNames: pushed,
        webParams: webParams,
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(_harness(router));

      expect(find.text('realunit.ch'), findsOneWidget);

      await tester.tap(_tileWithSubtitle('realunit.ch'));
      await tester.pumpAndSettle();

      // No url_launcher call — the website opens in-app via WebViewPage.
      expect(launcher.calls, isEmpty);
      expect(pushed, [AppRoutes.webView]);
      expect(webParams, hasLength(1));
      expect(webParams.single.url, Uri.parse('https://realunit.ch'));
      expect(webParams.single.title, isNotEmpty);
    });

    testWidgets('Imprint block shows the static company name + address', (tester) async {
      final router = _routerFor();
      addTearDown(router.dispose);

      await tester.pumpWidget(_harness(router));

      expect(find.text('RealUnit Schweiz AG'), findsOneWidget);
      expect(
        find.text('Schochenmühlestrasse 6\n6340 Baar, Schweiz'),
        findsOneWidget,
      );
    });
  });
}
