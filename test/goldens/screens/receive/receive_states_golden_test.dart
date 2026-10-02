import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/screens/receive/receive_page.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';

import '../../../helper/helper.dart';

// `receive_page_default` (bottom-sheet variant: handlebar, no AppBar) lives in
// `receive_golden_test.dart`. The router actually pushes the full-page variant
// (`router_config.dart:210` → `ReceivePage(isBottomSheet: false)`): an AppBar
// with a back arrow and no handlebar. This file covers that routed surface.
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
      'full page — AppBar with back arrow, no handlebar',
      fileName: 'receive_page_full_page',
      constraints: phoneConstraints,
      builder: () {
        return wrapForGolden(const ReceivePage(isBottomSheet: false));
      },
    );

    goldenTest(
      'full page with Send CTA',
      fileName: 'receive_page_full_page_send',
      constraints: phoneConstraints,
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
        return wrapForGolden(const ReceivePage(isBottomSheet: false));
      },
    );
  });
}
