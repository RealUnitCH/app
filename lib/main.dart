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
import 'package:realunit_wallet/setup/lifecycle_initializer.dart';
import 'package:realunit_wallet/setup/routing/router_config.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/setup/routing/routes/onboarding_routes.dart';
import 'package:realunit_wallet/setup/routing/routes/pin_routes.dart';
import 'package:realunit_wallet/styles/colors.dart';
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
  ErrorWidget.builder = (details) => _RealUnitErrorView(details: details);
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
    final pinState = getIt<PinAuthCubit>().state;

    if (homeState.isLoadingWallet) return;

    String targetRoute;
    if (!homeState.softwareTermsAccepted) {
      targetRoute = AppRoutes.home;
    } else if (!homeState.hasWallet) {
      targetRoute = OnboardingRoutes.welcome;
    } else if (!homeState.onboardingCompleted) {
      targetRoute = OnboardingRoutes.completed;
    } else if (!pinState.isPinSetup) {
      targetRoute = PinRoutes.setup;
    } else if (!pinState.isPinVerified) {
      targetRoute = PinRoutes.verify;
    } else if (homeState.bitboxAddressRecoveryNeeded) {
      // A BitBox wallet was persisted with an empty/invalid address — divert to
      // the re-pairing recovery flow instead of loading it into the dashboard
      // (which would crash the build via `EthereumAddress.fromHex("")`).
      targetRoute = AppRoutes.bitboxAddressRecovery;
    } else if (homeState.openWallet == null) {
      // Wallet not loaded yet — trigger load and wait for HomeBloc update
      _loadWalletIfNeeded();
      return;
    } else {
      targetRoute = AppRoutes.dashboard;
    }

    routerConfig.goNamed(targetRoute);
  }
}

/// Test-only seam for [_RealUnitErrorView]. The widget is private (so
/// [ErrorWidget.builder] can't be swapped from outside), but its last-resort
/// rendering is worth pinning. Constructs exactly what [_installErrorHandlers]
/// wires into [ErrorWidget.builder].
@visibleForTesting
Widget buildRealUnitErrorView(FlutterErrorDetails details) => _RealUnitErrorView(details: details);

/// Minimal on-brand replacement for the default grey [ErrorWidget]. Rendered by
/// [ErrorWidget.builder] for any uncaught build/paint exception, so it lives
/// outside the [MaterialApp] localization scope — the copy is deliberately
/// hardcoded (no `S.of(context)`) because this is a last-resort surface that
/// must render even when localization is unavailable. In debug it also shows
/// the exception text to keep diagnosis fast; release shows only the friendly
/// line.
class _RealUnitErrorView extends StatelessWidget {
  const _RealUnitErrorView({required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Container(
      color: RealUnitColors.neutral50,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          Icon(Icons.error_outline, color: RealUnitColors.status.red600, size: 48),
          const Text(
            'Something went wrong. Please restart the app.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: RealUnitColors.neutral900,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (kDebugMode)
            Text(
              details.exceptionAsString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: RealUnitColors.neutral500),
            ),
        ],
      ),
    ),
  );
}
