import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/repository/settings_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/settings_network/settings_network_page.dart';

import '../../helper/helper.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository settingsRepository;
  late SettingsBloc settingsBloc;
  late AppStore appStore;

  setUp(() {
    settingsRepository = MockSettingsRepository();
    appStore = AppStore();

    when(() => settingsRepository.language).thenReturn('de');
    when(() => settingsRepository.currency).thenReturn('CHF');
    when(() => settingsRepository.networkMode).thenReturn(NetworkMode.testnet);

    settingsBloc = SettingsBloc(settingsRepository);

    final getIt = GetIt.instance;
    if (getIt.isRegistered<SettingsBloc>()) {
      getIt.unregister<SettingsBloc>();
    }
    if (getIt.isRegistered<AppStore>()) {
      getIt.unregister<AppStore>();
    }
    getIt.registerSingleton<SettingsBloc>(settingsBloc);
    getIt.registerSingleton<AppStore>(appStore);
  });

  tearDown(() async {
    await settingsBloc.close();
    await GetIt.instance.reset();
  });

  group('SettingsNetworkPage', () {
    testWidgets('displays both network options', (tester) async {
      await tester.pumpApp(const SettingsNetworkPage());

      expect(find.text('Testnet'), findsOneWidget);
      expect(find.text('Mainnet'), findsOneWidget);
    });

    testWidgets('shows checkmark on currently selected network mode',
        (tester) async {
      await tester.pumpApp(const SettingsNetworkPage());

      // Testnet should have checkmark (default)
      final checkIcons = find.byIcon(Icons.check);
      expect(checkIcons, findsOneWidget);
    });

    testWidgets('tapping mainnet switches network mode', (tester) async {
      await tester.pumpApp(const SettingsNetworkPage());

      // Tap on Mainnet
      await tester.tap(find.text('Mainnet'));
      await tester.pumpAndSettle();

      // Bloc state should be updated
      expect(settingsBloc.state.networkMode, equals(NetworkMode.mainnet));
    });

    testWidgets('tapping testnet switches network mode', (tester) async {
      // Start with mainnet
      when(() => settingsRepository.networkMode).thenReturn(NetworkMode.mainnet);
      settingsBloc = SettingsBloc(settingsRepository);
      GetIt.instance.unregister<SettingsBloc>();
      GetIt.instance.registerSingleton<SettingsBloc>(settingsBloc);

      await tester.pumpApp(const SettingsNetworkPage());

      // Tap on Testnet
      await tester.tap(find.text('Testnet'));
      await tester.pumpAndSettle();

      // Bloc state should be updated
      expect(settingsBloc.state.networkMode, equals(NetworkMode.testnet));
    });

    testWidgets('switching network clears auth token', (tester) async {
      appStore.dfxAuthToken = 'test-token';

      await tester.pumpApp(const SettingsNetworkPage());

      // Tap on Mainnet
      await tester.tap(find.text('Mainnet'));
      await tester.pumpAndSettle();

      // Auth token should be cleared
      expect(appStore.dfxAuthToken, isNull);
    });

    testWidgets('checkmark moves when network is switched', (tester) async {
      await tester.pumpApp(const SettingsNetworkPage());

      // Initially testnet has checkmark
      expect(settingsBloc.state.networkMode, equals(NetworkMode.testnet));

      // Tap on Mainnet
      await tester.tap(find.text('Mainnet'));
      await tester.pumpAndSettle();

      // Now mainnet should be selected
      expect(settingsBloc.state.networkMode, equals(NetworkMode.mainnet));

      // Still only one checkmark
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
