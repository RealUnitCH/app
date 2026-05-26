import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/settings/settings_page.dart';

import '../../../helper/helper.dart';

void main() {
  late MockSettingsBloc settingsBloc;
  late MockHomeBloc homeBloc;
  late MockSoftwareWallet wallet;

  setUp(() {
    settingsBloc = MockSettingsBloc();
    homeBloc = MockHomeBloc();
    wallet = MockSoftwareWallet();

    when(() => wallet.walletType).thenReturn(WalletType.software);
    when(() => settingsBloc.state).thenReturn(const SettingsState());
    when(() => homeBloc.state).thenReturn(HomeState(openWallet: wallet));
  });

  setUpAll(() {
    GetIt.instance.registerSingleton<SettingsBloc>(MockSettingsBloc());
  });

  tearDownAll(() async {
    await GetIt.instance.reset();
  });

  group('$SettingsPage', () {
    goldenTest(
      'default state, software wallet open',
      fileName: 'settings_page_default',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () {
        // Re-register the per-test mock into GetIt so the BlocBuilder picks up
        // the state defined in setUp(). setUpAll() only registers once.
        if (GetIt.instance.isRegistered<SettingsBloc>()) {
          GetIt.instance.unregister<SettingsBloc>();
        }
        GetIt.instance.registerSingleton<SettingsBloc>(settingsBloc);

        return wrapForGolden(
          BlocProvider<HomeBloc>.value(
            value: homeBloc,
            child: const SettingsPage(),
          ),
        );
      },
    );
  });
}
