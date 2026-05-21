import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/balance_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/screens/pin/bloc/auth/pin_auth_cubit.dart';
import 'package:realunit_wallet/setup/di.dart';

class LifecycleInitializer extends StatefulWidget {
  final Widget child;

  const LifecycleInitializer({super.key, required this.child});

  @override
  State<LifecycleInitializer> createState() => _LifecycleInitializerState();
}

class _LifecycleInitializerState extends State<LifecycleInitializer> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onStateChange: _onStateChanged);
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
    getIt<BalanceService>().updateBalance(getIt<AppStore>().primaryAddress);
  }

  void _onInactive() {}

  void _onHidden() {
    getIt<PinAuthCubit>().onAppHidden();
    // Drop the mnemonic before iOS suspends the isolate. `lockCurrentWallet`
    // is defensive on its own — no try/catch / catchError by design, so a
    // Future.error surfaces in the Zone instead of being silently swallowed.
    // Microtask race to watch: if `_onResumed` ever calls
    // `ensureCurrentWalletUnlocked`, ordering against this pending lock matters.
    unawaited(getIt<WalletService>().lockCurrentWallet());
  }

  void _onPaused() {
    getIt<BalanceService>().cancelSync();
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
