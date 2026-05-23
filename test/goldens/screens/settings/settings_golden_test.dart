import 'package:alchemist/alchemist.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/settings/settings_page.dart';

import '../../../helper/helper.dart';

class _MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class _MockHomeBloc extends MockBloc<HomeEvent, HomeState> implements HomeBloc {}

void main() {
  late _MockSettingsBloc settingsBloc;
  late _MockHomeBloc homeBloc;

  setUp(() {
    settingsBloc = _MockSettingsBloc();
    homeBloc = _MockHomeBloc();

    when(() => settingsBloc.state).thenReturn(const SettingsState());
    when(() => homeBloc.state).thenReturn(const HomeState());
  });

  setUpAll(() {
    GetIt.instance.registerSingleton<SettingsBloc>(_MockSettingsBloc());
  });

  tearDownAll(() async {
    await GetIt.instance.reset();
  });

  group('$SettingsPage', () {
    goldenTest(
      'default state, no open wallet',
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
