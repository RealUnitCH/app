import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/utils/fuck_firebase.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/pin/bloc/auth/pin_auth_cubit.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/setup/error_handling/realunit_error_view.dart';
import 'package:realunit_wallet/setup/lifecycle_initializer.dart';
import 'package:realunit_wallet/setup/routing/boot_navigation.dart';
import 'package:realunit_wallet/setup/routing/router_config.dart';
import 'package:realunit_wallet/styles/themes.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  _installErrorHandlers();

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
  runApp(
    const LifecycleInitializer(child: WalletApp()),
  );
}

/// Defense-in-depth against uncaught build/paint exceptions. Without this, a
/// single throw inside a widget's `build` (e.g. the empty-BitBox-address
/// `EthereumAddress.fromHex("")` crash) surfaces in release as a bare grey
/// [ErrorWidget] with no branding and no signal to the user. We log every such
/// error and replace the grey box with a minimal on-brand surface.
void _installErrorHandlers() {
  final defaultOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    developer.log(
      'uncaught Flutter error: ${details.exceptionAsString()}',
      name: 'WalletApp',
      error: details.exception,
      stackTrace: details.stack,
    );
    defaultOnError?.call(details);
  };
  ErrorWidget.builder = (details) => RealUnitErrorView(details: details);
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
  State<WalletApp> createState() => _WalletAppState();
}

class _WalletAppState extends State<WalletApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _navigate());
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
        routerConfig: routerConfig,
        builder: (context, child) => MultiBlocListener(
          listeners: [
            BlocListener<HomeBloc, HomeState>(
              listener: (context, homeState) {
                if (!homeState.isLoadingWallet) {
                  _navigate();
                }
              },
            ),
            BlocListener<PinAuthCubit, PinAuthState>(
              listener: (context, pinState) {
                if (pinState.isPinVerified) {
                  _loadWalletIfNeeded();
                }
                _navigate();
              },
            ),
          ],
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
  );

  void _loadWalletIfNeeded() {
    final homeState = getIt<HomeBloc>().state;
    if (homeState.hasWallet && homeState.openWallet == null && !homeState.isLoadingWallet) {
      getIt<HomeBloc>().add(const LoadCurrentWalletEvent());
    }
  }

  void _navigate() {
    final homeState = getIt<HomeBloc>().state;
    final pin = getIt<PinAuthCubit>();
    final pinState = pin.state;
    final current = routerConfig.routerDelegate.currentConfiguration.uri.toString();

    final action = resolveBootNavigation(
      isLoadingWallet: homeState.isLoadingWallet,
      softwareTermsAccepted: homeState.softwareTermsAccepted,
      hasWallet: homeState.hasWallet,
      onboardingCompleted: homeState.onboardingCompleted,
      isPinSetup: pinState.isPinSetup,
      isPinVerified: pinState.isPinVerified,
      bitboxAddressRecoveryNeeded: homeState.bitboxAddressRecoveryNeeded,
      walletLoaded: homeState.openWallet != null,
      currentLocation: current,
      resumeLocation: pin.peekResumeLocation(),
    );

    applyBootNavAction(
      action,
      routerConfig,
      onLoadWallet: _loadWalletIfNeeded,
      onClearResume: pin.clearResumeLocation,
    );
  }
}
