import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/repository/settings_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/styles/currency.dart';
import 'package:realunit_wallet/styles/language.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late SettingsRepository settingsRepository;
  late AppStore appStore;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settingsRepository = MockSettingsRepository();
    appStore = AppStore();

    when(() => settingsRepository.language).thenReturn('de');
    when(() => settingsRepository.currency).thenReturn('CHF');
    when(() => settingsRepository.networkMode).thenReturn(NetworkMode.testnet);

    final getIt = GetIt.instance;
    if (getIt.isRegistered<AppStore>()) {
      getIt.unregister<AppStore>();
    }
    getIt.registerSingleton<AppStore>(appStore);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  group('SettingsBloc', () {
    test('initial state has correct values from repository', () {
      final bloc = SettingsBloc(settingsRepository);

      expect(bloc.state.language, equals(Language.de));
      expect(bloc.state.currency, equals(Currency.chf));
      expect(bloc.state.networkMode, equals(NetworkMode.testnet));
    });

    blocTest<SettingsBloc, SettingsState>(
      'SetNetworkModeEvent updates networkMode to mainnet',
      build: () => SettingsBloc(settingsRepository),
      act: (bloc) => bloc.add(SetNetworkModeEvent(NetworkMode.mainnet)),
      expect: () => [
        isA<SettingsState>().having(
          (s) => s.networkMode,
          'networkMode',
          NetworkMode.mainnet,
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'SetNetworkModeEvent updates networkMode to testnet',
      setUp: () {
        when(() => settingsRepository.networkMode).thenReturn(NetworkMode.mainnet);
      },
      build: () => SettingsBloc(settingsRepository),
      act: (bloc) => bloc.add(SetNetworkModeEvent(NetworkMode.testnet)),
      expect: () => [
        isA<SettingsState>().having(
          (s) => s.networkMode,
          'networkMode',
          NetworkMode.testnet,
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'SetNetworkModeEvent clears dfxAuthToken',
      setUp: () {
        GetIt.instance<AppStore>().dfxAuthToken = 'test-token';
      },
      build: () => SettingsBloc(settingsRepository),
      act: (bloc) => bloc.add(SetNetworkModeEvent(NetworkMode.mainnet)),
      verify: (_) {
        expect(GetIt.instance<AppStore>().dfxAuthToken, isNull);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'SetLanguageEvent updates language',
      build: () => SettingsBloc(settingsRepository),
      act: (bloc) => bloc.add(SetLanguageEvent(Language.en)),
      expect: () => [
        isA<SettingsState>().having(
          (s) => s.language,
          'language',
          Language.en,
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'SetCurrencyEvent updates currency',
      build: () => SettingsBloc(settingsRepository),
      act: (bloc) => bloc.add(SetCurrencyEvent(Currency.eur)),
      expect: () => [
        isA<SettingsState>().having(
          (s) => s.currency,
          'currency',
          Currency.eur,
        ),
      ],
    );
  });
}
