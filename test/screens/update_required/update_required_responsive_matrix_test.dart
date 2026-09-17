// Responsive matrix gate for UpdateRequiredPage sticky CTAs.
//
// Proves the primary Update button stays fully tappable across the full
// device × text-scale matrix. Catalog self-test requires a direct import of
// the production page (≤1 hop).
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/client_policy/real_unit_client_policy.dart';
import 'package:realunit_wallet/packages/utils/marketing_version.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/update_required/bloc/client_policy_cubit.dart';
import 'package:realunit_wallet/screens/update_required/update_required_page.dart';
import 'package:realunit_wallet/styles/themes.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../helper/helper.dart';

class _MockClientPolicyCubit extends MockCubit<ClientPolicyState>
    implements ClientPolicyCubit {}

class _FakeUrlLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
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
  }) async =>
      true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async => true;

  @override
  Future<bool> supportsMode(PreferredLaunchMode mode) async => true;

  @override
  Future<bool> supportsCloseForMode(PreferredLaunchMode mode) async => false;
}

const _playStoreUrl =
    'https://play.google.com/store/apps/details?id=swiss.realunit.app';

const _policy = RealUnitClientPolicy(
  severity: ClientPolicySeverity.hard,
  playStoreUrl: _playStoreUrl,
);

Future<void> _pumpScreen(
  WidgetTester tester,
  Widget widget,
  MediaQueryData mediaQuery,
) async {
  await tester.binding.setSurfaceSize(mediaQuery.size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MediaQuery(
      data: mediaQuery,
      child: MaterialApp(
        theme: realUnitTheme,
        locale: const Locale('de'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: widget,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  late _MockClientPolicyCubit clientPolicyCubit;
  late MockHomeBloc homeBloc;
  late UrlLauncherPlatform originalLauncher;
  final AppStore appStore = MockAppStore();

  setUpAll(() {
    originalLauncher = UrlLauncherPlatform.instance;
    UrlLauncherPlatform.instance = _FakeUrlLauncher();
    GetIt.instance.registerSingleton<AppStore>(appStore);
  });

  tearDownAll(() async {
    UrlLauncherPlatform.instance = originalLauncher;
    await GetIt.instance.reset();
  });

  setUp(() {
    when(() => appStore.isWalletLoaded).thenReturn(false);

    homeBloc = MockHomeBloc();
    when(() => homeBloc.state).thenReturn(const HomeState());
    whenListen(
      homeBloc,
      const Stream<HomeState>.empty(),
      initialState: const HomeState(),
    );

    clientPolicyCubit = _MockClientPolicyCubit();
    const loaded = ClientPolicyLoaded(_policy);
    when(() => clientPolicyCubit.state).thenReturn(loaded);
    whenListen(
      clientPolicyCubit,
      const Stream<ClientPolicyState>.empty(),
      initialState: loaded,
    );
  });

  Widget buildSubject() => MultiBlocProvider(
        providers: [
          BlocProvider<ClientPolicyCubit>.value(value: clientPolicyCubit),
          BlocProvider<HomeBloc>.value(value: homeBloc),
        ],
        child: const UpdateRequiredPage(),
      );

  group('UpdateRequiredPage responsive matrix (full device × textScale)', () {
    for (final cell in kFullResponsiveMatrix) {
      testWidgets(cell.id, (tester) async {
        await withTargetPlatform(cell.device.platform, () async {
          await expectNoLayoutOverflow(
            tester,
            () async {
              await _pumpScreen(tester, buildSubject(), cell.mediaQuery);
            },
            reason: 'overflow on ${cell.label}',
          );

          await expectFullyTappable(
            tester,
            find.widgetWithText(AppFilledButton, S.current.updateRequiredCta),
            within: find.byType(UpdateRequiredPage),
            reason: '${cell.label}: Update CTA not tappable',
          );
        });
      });
    }
  });
}
