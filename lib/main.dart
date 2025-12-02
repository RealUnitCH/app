import 'dart:developer' as developer;

import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/balance_service.dart';
import 'package:realunit_wallet/packages/utils/fuck_firebase.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/styles/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

Future<void> main() async {
  // try {
  WidgetsFlutterBinding.ensureInitialized();
  await fuckFirebase();
  final databaseKey = await setupEssentials();
  await finishSetup(databaseKey);

  runApp(const WalletApp());
  // } catch (e) {
  //   runApp(
  //     MaterialApp(
  //       home: Scaffold(
  //         body: Container(
  //           margin:
  //               const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
  //           child: Text(
  //             'Error:\n${e.toString()}',
  //             style: const TextStyle(fontSize: 22, color: Colors.black),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
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
  }

  void _onDetached() => debugPrint('detached');

  void _onResumed() {
    getIt<BalanceService>().updateERC20Balances(getIt<AppStore>().primaryAddress);
  }

  void _onInactive() => developer.log('inactive', name: 'AppLifecycleListener');

  void _onHidden() => developer.log('hidden', name: 'AppLifecycleListener');

  void _onPaused() {
    getIt<BalanceService>().cancelSync();
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: getIt<HomeBloc>()),
          BlocProvider.value(value: getIt<SettingsBloc>()),
        ],
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) => MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: realUnitTheme,
            supportedLocales: S.delegate.supportedLocales,
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            locale: Locale(state.language.code),
            routerConfig: getIt<GoRouter>(),
            builder: (context, child) => BlocListener<HomeBloc, HomeState>(
              listener: (context, state) {
                if (!state.isLoadingWallet) {
                  getIt<GoRouter>().go(state.openWallet != null ? '/dashboard' : '/welcome');
                }
              },
              child: child,
            ),
          ),
        ),
      );
}
