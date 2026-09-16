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
    when(() => repo.currency).thenReturn('EUR');
    when(() => repo.hasStoredCurrency).thenReturn(false);
    when(() => repo.networkMode).thenReturn(NetworkMode.mainnet);
    when(() => repo.insiderFeaturesUnlocked).thenReturn(false);
    when(() => repo.insiderPayEnabled).thenReturn(false);
    when(() => repo.insiderSendEnabled).thenReturn(false);
    when(() => repo.insiderReferralEnabled).thenReturn(false);
    when(() => repo.insiderBonusEnabled).thenReturn(false);
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
      when(() => repo.insiderFeaturesUnlocked).thenReturn(true);
      when(() => repo.insiderPayEnabled).thenReturn(true);
      when(() => repo.insiderSendEnabled).thenReturn(false);
      when(() => repo.insiderReferralEnabled).thenReturn(false);
      when(() => repo.insiderBonusEnabled).thenReturn(false);

      final bloc = build();

      expect(bloc.state.language, Language.de);
      expect(bloc.state.currency, Currency.eur);
      expect(bloc.state.networkMode, NetworkMode.testnet);
      expect(bloc.state.hideAmounts, isFalse);
      expect(bloc.state.insiderFeaturesUnlocked, isTrue);
      expect(bloc.state.insiderPayEnabled, isTrue);
      expect(bloc.state.insiderSendEnabled, isFalse);
      expect(bloc.state.insiderReferralEnabled, isFalse);
      expect(bloc.state.insiderBonusEnabled, isFalse);
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

    blocTest<SettingsBloc, SettingsState>(
      'ApplyAccountCurrencyEvent emits the account currency when nothing is stored',
      build: build,
      act: (bloc) => bloc.add(const ApplyAccountCurrencyEvent(Currency.chf)),
      expect: () => [
        isA<SettingsState>().having((s) => s.currency, 'currency', Currency.chf),
      ],
      verify: (bloc) {
        verifyNever(() => repo.currency = any());
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'ApplyAccountCurrencyEvent is ignored when the user already stored a currency',
      build: build,
      setUp: () => when(() => repo.hasStoredCurrency).thenReturn(true),
      act: (bloc) => bloc.add(const ApplyAccountCurrencyEvent(Currency.chf)),
      expect: () => <SettingsState>[],
    );

    blocTest<SettingsBloc, SettingsState>(
      'ClearAccountCurrencyEvent restores the unset default when nothing is stored',
      build: build,
      seed: () => const SettingsState(currency: Currency.chf),
      act: (bloc) => bloc.add(const ClearAccountCurrencyEvent()),
      expect: () => [
        isA<SettingsState>().having((s) => s.currency, 'currency', Currency.eur),
      ],
      verify: (bloc) {
        verifyNever(() => repo.currency = any());
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'ClearAccountCurrencyEvent is ignored when the user already stored a currency',
      build: build,
      setUp: () => when(() => repo.hasStoredCurrency).thenReturn(true),
      seed: () => const SettingsState(currency: Currency.chf),
      act: (bloc) => bloc.add(const ClearAccountCurrencyEvent()),
      expect: () => <SettingsState>[],
    );

    test('SetNetworkModeEvent writes the new mode, refreshes auth, and emits', () async {
      final bloc = build();

      bloc.add(const SetNetworkModeEvent(NetworkMode.testnet));
      await bloc.stream.firstWhere((s) => s.networkMode == NetworkMode.testnet);

      expect(bloc.state.networkMode, NetworkMode.testnet);
      expect(authRefreshCount, 1);
      verify(() => repo.networkMode = NetworkMode.testnet).called(1);
    });

    test('SetNetworkModeEvent invokes onNetworkModeChanged after auth refresh', () async {
      final callOrder = <String>[];
      final bloc = SettingsBloc(
        repo,
        () async {
          callOrder.add('auth');
        },
        onNetworkModeChanged: () => callOrder.add('invalidate'),
      );

      bloc.add(const SetNetworkModeEvent(NetworkMode.testnet));
      await bloc.stream.firstWhere((s) => s.networkMode == NetworkMode.testnet);

      // Reference-data invalidation must happen after the auth refresh so
      // the next fetch hits the new backend with the new token.
      expect(callOrder, ['auth', 'invalidate']);
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

    // hideAmounts is intentionally session-only (SettingsRepository has no field for it).
    test('ToggleHideAmountEvent flips state without persisting (session-only by design)', () async {
      final bloc = build();

      bloc.add(const ToggleHideAmountEvent());
      await bloc.stream.firstWhere((s) => s.hideAmounts == true);

      expect(bloc.state.hideAmounts, isTrue);
      verifyNever(() => repo.language = any()); // proxy: no repo call at all
    });

    blocTest<SettingsBloc, SettingsState>(
      'UnlockInsiderFeaturesEvent persists to the repo and emits insiderFeaturesUnlocked=true',
      build: build,
      act: (bloc) => bloc.add(const UnlockInsiderFeaturesEvent()),
      verify: (bloc) {
        expect(bloc.state.insiderFeaturesUnlocked, isTrue);
        expect(bloc.state.insiderPayEnabled, isFalse);
        expect(bloc.state.insiderSendEnabled, isFalse);
        expect(bloc.state.insiderReferralEnabled, isFalse);
        expect(bloc.state.insiderBonusEnabled, isFalse);
        verify(() => repo.insiderFeaturesUnlocked = true).called(1);
        verifyNever(() => repo.insiderPayEnabled = any());
        verifyNever(() => repo.insiderSendEnabled = any());
        verifyNever(() => repo.insiderReferralEnabled = any());
        verifyNever(() => repo.insiderBonusEnabled = any());
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'SetInsiderFeatureEnabledEvent(pay, true) persists and emits',
      build: build,
      act: (bloc) => bloc.add(
        const SetInsiderFeatureEnabledEvent(InsiderFeature.pay, true),
      ),
      verify: (bloc) {
        expect(bloc.state.insiderPayEnabled, isTrue);
        verify(() => repo.insiderPayEnabled = true).called(1);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'SetInsiderFeatureEnabledEvent(pay, false) persists and emits',
      build: build,
      seed: () => const SettingsState(insiderPayEnabled: true),
      act: (bloc) => bloc.add(
        const SetInsiderFeatureEnabledEvent(InsiderFeature.pay, false),
      ),
      verify: (bloc) {
        expect(bloc.state.insiderPayEnabled, isFalse);
        verify(() => repo.insiderPayEnabled = false).called(1);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'SetInsiderFeatureEnabledEvent(send, true) persists and emits',
      build: build,
      act: (bloc) => bloc.add(
        const SetInsiderFeatureEnabledEvent(InsiderFeature.send, true),
      ),
      verify: (bloc) {
        expect(bloc.state.insiderSendEnabled, isTrue);
        verify(() => repo.insiderSendEnabled = true).called(1);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'SetInsiderFeatureEnabledEvent(send, false) persists and emits',
      build: build,
      seed: () => const SettingsState(insiderSendEnabled: true),
      act: (bloc) => bloc.add(
        const SetInsiderFeatureEnabledEvent(InsiderFeature.send, false),
      ),
      verify: (bloc) {
        expect(bloc.state.insiderSendEnabled, isFalse);
        verify(() => repo.insiderSendEnabled = false).called(1);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'SetInsiderFeatureEnabledEvent(referral, true) persists and emits',
      build: build,
      act: (bloc) => bloc.add(
        const SetInsiderFeatureEnabledEvent(InsiderFeature.referral, true),
      ),
      verify: (bloc) {
        expect(bloc.state.insiderReferralEnabled, isTrue);
        verify(() => repo.insiderReferralEnabled = true).called(1);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'SetInsiderFeatureEnabledEvent(referral, false) persists and emits',
      build: build,
      seed: () => const SettingsState(insiderReferralEnabled: true),
      act: (bloc) => bloc.add(
        const SetInsiderFeatureEnabledEvent(InsiderFeature.referral, false),
      ),
      verify: (bloc) {
        expect(bloc.state.insiderReferralEnabled, isFalse);
        verify(() => repo.insiderReferralEnabled = false).called(1);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'SetInsiderFeatureEnabledEvent(bonus, true) persists and emits',
      build: build,
      act: (bloc) => bloc.add(
        const SetInsiderFeatureEnabledEvent(InsiderFeature.bonus, true),
      ),
      verify: (bloc) {
        expect(bloc.state.insiderBonusEnabled, isTrue);
        verify(() => repo.insiderBonusEnabled = true).called(1);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'SetInsiderFeatureEnabledEvent(bonus, false) persists and emits',
      build: build,
      seed: () => const SettingsState(insiderBonusEnabled: true),
      act: (bloc) => bloc.add(
        const SetInsiderFeatureEnabledEvent(InsiderFeature.bonus, false),
      ),
      verify: (bloc) {
        expect(bloc.state.insiderBonusEnabled, isFalse);
        verify(() => repo.insiderBonusEnabled = false).called(1);
      },
    );
  });
}
