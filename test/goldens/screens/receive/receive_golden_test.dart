import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/screens/receive/receive_page.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';

import '../../../helper/helper.dart';

void main() {
  setUpAll(() {
    final getIt = GetIt.instance;
    final appStore = MockAppStore();
    when(() => appStore.primaryAddress)
        .thenReturn('0xcabd3f4b10a7089986e708d19140bfc98e5880c0');
    getIt.registerSingleton<AppStore>(appStore);
    final settingsBloc = MockSettingsBloc();
    when(() => settingsBloc.state).thenReturn(const SettingsState());
    getIt.registerSingleton<SettingsBloc>(settingsBloc);
  });

  tearDownAll(() async => GetIt.instance.reset());

  group('$ReceivePage', () {
    goldenTest(
      'default bottom sheet',
      fileName: 'receive_page_default',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () {
        return wrapForGolden(const ReceivePage());
      },
    );

    goldenTest(
      'default bottom sheet with Send CTA',
      fileName: 'receive_page_default_send',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () {
        final settingsBloc = MockSettingsBloc();
        when(() => settingsBloc.state).thenReturn(
          const SettingsState(
            insiderFeaturesUnlocked: true,
            insiderSendEnabled: true,
          ),
        );
        if (GetIt.instance.isRegistered<SettingsBloc>()) {
          GetIt.instance.unregister<SettingsBloc>();
        }
        GetIt.instance.registerSingleton<SettingsBloc>(settingsBloc);
        return wrapForGolden(const ReceivePage());
      },
    );
  });
}
