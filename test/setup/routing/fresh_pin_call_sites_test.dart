import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/client_policy/real_unit_client_policy.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_summary_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_referral_service.dart';
import 'package:realunit_wallet/packages/utils/marketing_version.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/pin/bloc/auth/pin_auth_cubit.dart';
import 'package:realunit_wallet/screens/pin/verify_pin_page.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/settings/settings_page.dart';
import 'package:realunit_wallet/screens/settings_security/cubits/settings_security_cubit.dart';
import 'package:realunit_wallet/screens/settings_security/settings_security_page.dart';
import 'package:realunit_wallet/screens/update_required/bloc/client_policy_cubit.dart';
import 'package:realunit_wallet/screens/update_required/update_required_page.dart';
import 'package:realunit_wallet/setup/routing/pin_route_guard.dart';
import 'package:realunit_wallet/setup/routing/routes/app_link_entry.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/setup/routing/routes/pin_routes.dart';
import 'package:realunit_wallet/setup/routing/routes/settings_routes.dart';

import '../../helper/helper.dart';

class _MockPinAuthCubit extends Mock implements PinAuthCubit {}

class _MockClientPolicyCubit extends MockCubit<ClientPolicyState> implements ClientPolicyCubit {}

class _MockSettingsSecurityCubit extends MockCubit<SettingsSecurityState>
    implements SettingsSecurityCubit {}

// The screens that open the recovery phrase or the PIN change go through the
// PIN gate first; the router lets the protected route open after that entry.
void main() {
  late MockHomeBloc homeBloc;

  setUp(() async {
    await GetIt.instance.reset();
    clearFreshPinGrant();
    final pinAuthCubit = _MockPinAuthCubit();
    when(
      () => pinAuthCubit.state,
    ).thenReturn(const PinAuthState(isPinSetup: true, isPinVerified: true));
    final wallet = MockSoftwareWallet();
    when(() => wallet.walletType).thenReturn(WalletType.software);
    homeBloc = MockHomeBloc();
    final homeState = HomeState(hasWallet: true, openWallet: wallet);
    when(() => homeBloc.state).thenReturn(homeState);
    whenListen(homeBloc, const Stream<HomeState>.empty(), initialState: homeState);

    final settingsBloc = MockSettingsBloc();
    when(() => settingsBloc.state).thenReturn(const SettingsState());
    final referral = MockRealUnitReferralService();
    when(() => referral.getSummary()).thenAnswer(
      (_) async => const ReferralSummaryDto(
        eligible: false,
        termsAccepted: false,
        openCount: 0,
        creditedCount: 0,
        realuSum: 0,
        chfSum: 0,
      ),
    );
    final appStore = MockAppStore();
    when(() => appStore.isWalletLoaded).thenReturn(true);
    when(() => appStore.wallet).thenReturn(wallet);

    GetIt.instance
      ..registerSingleton<PinAuthCubit>(pinAuthCubit)
      ..registerSingleton<HomeBloc>(homeBloc)
      ..registerSingleton<SettingsBloc>(settingsBloc)
      ..registerSingleton<RealUnitReferralService>(referral)
      ..registerSingleton<AppStore>(appStore);
  });

  tearDown(() async {
    clearFreshPinGrant();
    await GetIt.instance.reset();
  });

  Future<GoRouter> pumpScreen(WidgetTester tester, Widget screen) async {
    late final GoRouter router;
    router = GoRouter(
      initialLocation: '/screen',
      redirect: (context, state) => appRouterRedirect(state, router),
      onException: appLinkOnException,
      routes: [
        GoRoute(path: '/screen', builder: (_, _) => screen),
        GoRoute(
          name: PinRoutes.gate,
          path: '/pinGate',
          builder: (_, state) {
            final params = state.extra! as VerifyPinParams;
            return Scaffold(
              body: TextButton(
                key: const Key('pinEntered'),
                onPressed: params.onAuthenticated,
                child: Text(params.description ?? ''),
              ),
            );
          },
        ),
        GoRoute(
          name: PinRoutes.verify,
          path: '/verifyPin',
          builder: (_, _) => const Scaffold(body: Text('VERIFY')),
        ),
        GoRoute(
          name: PinRoutes.setup,
          path: '/setupPin',
          builder: (_, _) => const Scaffold(body: Text('SETUP')),
        ),
        GoRoute(
          name: AppRoutes.receive,
          path: '/receive',
          builder: (_, _) => const Scaffold(body: Text('RECEIVE')),
        ),
        GoRoute(
          name: SettingsRoutes.seed,
          path: '/settings/seed',
          builder: (_, _) => const Scaffold(body: Text('SEED')),
        ),
        GoRoute(
          name: SettingsRoutes.changePin,
          path: '/settings/security/changePin',
          builder: (_, state) {
            final params = state.extra! as ChangePinParams;
            return Scaffold(
              body: TextButton(onPressed: params.onCompleted, child: const Text('CHANGE_PIN')),
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [BlocProvider<HomeBloc>.value(value: homeBloc)],
        child: MaterialApp.router(
          locale: const Locale('de'),
          routerConfig: router,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> enterPin(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('pinEntered')));
    await tester.pumpAndSettle();
  }

  testWidgets('the wallet backup in the settings opens the recovery phrase after the PIN', (
    tester,
  ) async {
    final router = await pumpScreen(
      tester,
      const SettingsPage(unavailablePollInterval: Duration.zero),
    );

    await tester.ensureVisible(find.text(S.current.settingsWalletBackup));
    await tester.tap(find.text(S.current.settingsWalletBackup));
    await tester.pumpAndSettle();
    expect(find.text(S.current.pinVerifySeedDescription), findsOneWidget);
    expect(find.text('SEED'), findsNothing);

    await enterPin(tester);
    expect(find.text('SEED'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
  });

  testWidgets('the backup on the required update opens the recovery phrase after the PIN', (
    tester,
  ) async {
    final clientPolicyCubit = _MockClientPolicyCubit();
    const loaded = ClientPolicyLoaded(
      RealUnitClientPolicy(severity: ClientPolicySeverity.hard),
    );
    when(() => clientPolicyCubit.state).thenReturn(loaded);
    whenListen(
      clientPolicyCubit,
      const Stream<ClientPolicyState>.empty(),
      initialState: loaded,
    );
    await pumpScreen(
      tester,
      BlocProvider<ClientPolicyCubit>.value(
        value: clientPolicyCubit,
        child: const UpdateRequiredPage(),
      ),
    );

    final backup = find.text(S.current.updateRequiredBackup);
    await tester.ensureVisible(backup);
    await tester.tap(backup);
    await tester.pumpAndSettle();
    expect(find.text(S.current.pinVerifySeedDescription), findsOneWidget);

    await enterPin(tester);
    expect(find.text('SEED'), findsOneWidget);
  });

  testWidgets('the PIN change in the security settings opens after the PIN', (tester) async {
    final cubit = _MockSettingsSecurityCubit();
    when(() => cubit.state).thenReturn(const SettingsSecurityState());
    await pumpScreen(
      tester,
      BlocProvider<SettingsSecurityCubit>.value(
        value: cubit,
        child: const SettingsSecurityView(),
      ),
    );

    await tester.tap(find.text(S.current.settingsChangePin));
    await tester.pumpAndSettle();
    expect(find.text(S.current.settingsChangePinVerifyDescription), findsOneWidget);

    await enterPin(tester);
    expect(find.text('CHANGE_PIN'), findsOneWidget);

    await tester.tap(find.text('CHANGE_PIN'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(S.current.pinChangeSuccess), findsOneWidget);
    expect(find.text('CHANGE_PIN'), findsNothing);
  });
}
