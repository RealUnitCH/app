import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/repository/settings_repository.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/styles/currency.dart';
import 'package:realunit_wallet/styles/language.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late _MockSettingsRepository repo;
  late int authRefreshCount;

  setUp(() {
    repo = _MockSettingsRepository();
    authRefreshCount = 0;
    // Defaults — sane values for the initial state.
    when(() => repo.language).thenReturn('en');
    when(() => repo.currency).thenReturn('CHF');
    when(() => repo.networkMode).thenReturn(NetworkMode.mainnet);
  });

  SettingsBloc build() => SettingsBloc(
        repo,
        () async {
          authRefreshCount++;
        },
      );

  group('$SettingsBloc', () {
    test('initial state reads from the repository', () {
      when(() => repo.language).thenReturn('de');
      when(() => repo.currency).thenReturn('EUR');
      when(() => repo.networkMode).thenReturn(NetworkMode.testnet);

      final bloc = build();

      expect(bloc.state.language, Language.de);
      expect(bloc.state.currency, Currency.eur);
      expect(bloc.state.networkMode, NetworkMode.testnet);
      expect(bloc.state.hideAmounts, isFalse);
    });

    blocTest<SettingsBloc, SettingsState>(
      'SetLanguageEvent writes to the repo and emits the new language',
      build: build,
      act: (bloc) => bloc.add(const SetLanguageEvent(Language.de)),
      verify: (bloc) {
        expect(bloc.state.language, Language.de);
        verify(() => repo.language = 'de').called(1);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'SetCurrencyEvent writes to the repo and emits the new currency',
      build: build,
      act: (bloc) => bloc.add(const SetCurrencyEvent(Currency.eur)),
      verify: (bloc) {
        expect(bloc.state.currency, Currency.eur);
        verify(() => repo.currency = 'EUR').called(1);
      },
    );

    test('SetNetworkModeEvent writes the new mode, refreshes auth, and emits', () async {
      final bloc = build();

      bloc.add(const SetNetworkModeEvent(NetworkMode.testnet));
      await bloc.stream.firstWhere((s) => s.networkMode == NetworkMode.testnet);

      expect(bloc.state.networkMode, NetworkMode.testnet);
      expect(authRefreshCount, 1);
      verify(() => repo.networkMode = NetworkMode.testnet).called(1);
    });

    blocTest<SettingsBloc, SettingsState>(
      'ToggleHideAmountEvent flips hideAmounts each time',
      build: build,
      act: (bloc) {
        bloc.add(const ToggleHideAmountEvent());
        bloc.add(const ToggleHideAmountEvent());
      },
      verify: (bloc) {
        expect(bloc.state.hideAmounts, isFalse);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'a single ToggleHideAmountEvent sets hideAmounts=true',
      build: build,
      act: (bloc) => bloc.add(const ToggleHideAmountEvent()),
      verify: (bloc) {
        expect(bloc.state.hideAmounts, isTrue);
      },
    );
  });
}
