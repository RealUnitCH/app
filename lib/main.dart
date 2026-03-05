import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/balance_service.dart';
import 'package:realunit_wallet/packages/utils/fuck_firebase.dart';
import 'package:realunit_wallet/screens/dashboard/dashboard_page.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/onboarding/onboarding_completed_page.dart';
import 'package:realunit_wallet/screens/pin/bloc/auth/pin_auth_cubit.dart';
import 'package:realunit_wallet/screens/pin/setup_pin_page.dart';
import 'package:realunit_wallet/screens/pin/verify_pin_page.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/terms/terms_page.dart';
import 'package:realunit_wallet/styles/themes.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // only preserve splash screen for 3 seconds for release version
  if (kReleaseMode) {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
    await _initializeWithSplashDuration();
    FlutterNativeSplash.remove();
  } else {
    await _initialize();
  }
}

Future<void> _initialize() async {
  await fuckFirebase();
  final databaseKey = await setupEssentials();
  await finishSetup(databaseKey);
  runApp(const WalletApp());
}

Future<void> _initializeWithSplashDuration() async {
  await Future.wait([
    _initialize(),
    Future.delayed(const Duration(seconds: 3)),
  ]);
}

class WalletApp extends StatefulWidget {
  const WalletApp({super.key});

  @override
  State<StatefulWidget> createState() => _WalletAppState();
}

class _WalletAppState extends State<WalletApp> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onStateChange: _onStateChanged);
  }

  @override
  void dispose() {
    _listener.dispose();

    super.dispose();
  }

  void _onStateChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
        _onDetached();
      case AppLifecycleState.resumed:
        _onResumed();
      case AppLifecycleState.inactive:
        _onInactive();
      case AppLifecycleState.hidden:
        _onHidden();
      case AppLifecycleState.paused:
        _onPaused();
    }
    developer.log(state.name, name: 'AppLifecycleListener');
  }

  void _onDetached() {}

  void _onResumed() {
    getIt<PinAuthCubit>().onAppResumed();
    getIt<BalanceService>().updateBalances(getIt<AppStore>().primaryAddress);
  }

  void _onInactive() {}

  void _onHidden() {
    getIt<PinAuthCubit>().onAppHidden();
  }

  void _onPaused() {
    getIt<BalanceService>().cancelSync();
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: getIt<HomeBloc>()),
      BlocProvider.value(value: getIt<SettingsBloc>()),
      BlocProvider.value(value: getIt<PinAuthCubit>()),
    ],
    child: BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: realUnitTheme,
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        locale: Locale(settingsState.language.code),
        routerConfig: getIt<GoRouter>(),
        builder: (context, child) => MultiBlocListener(
          listeners: [
            BlocListener<HomeBloc, HomeState>(
              listener: (context, homeState) {
                if (!homeState.isLoadingWallet) {
                  _navigate(context);
                }
              },
            ),
            BlocListener<PinAuthCubit, PinAuthState>(
              listener: (context, pinState) {
                _navigate(context);
              },
            ),
          ],
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
  );

  void _navigate(BuildContext context) {
    final homeState = context.read<HomeBloc>().state;
    final pinState = context.read<PinAuthCubit>().state;

    if (homeState.isLoadingWallet) return;

    String targetRoute;
    if (!homeState.softwareTermsAccepted) {
      targetRoute = TermsPage.route;
    } else if (homeState.openWallet == null) {
      targetRoute = '/welcome';
    } else if (!homeState.onboardingCompleted) {
      targetRoute = OnboardingCompletedPage.route;
    } else if (!pinState.isPinSetup) {
      targetRoute = SetupPinPage.route;
    } else if (!pinState.isPinVerified) {
      targetRoute = VerifyPinPage.route;
    } else {
      targetRoute = DashboardPage.routeName;
    }

    getIt<GoRouter>().go(targetRoute);
  }
}
