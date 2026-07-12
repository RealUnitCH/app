import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_user_type.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/user_data.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/settings_user_data/cubit/settings_user_data_cubit.dart';
import 'package:realunit_wallet/styles/currency.dart';
import 'package:realunit_wallet/styles/language.dart';

void main() {
  group('$HomeState defaults + copyWith', () {
    test('defaults: no wallet, idle, onboarding incomplete', () {
      const state = HomeState();
      expect(state.hasWallet, isFalse);
      expect(state.openWallet, isNull);
      expect(state.isLoadingWallet, isFalse);
      expect(state.onboardingCompleted, isFalse);
      expect(state.softwareTermsAccepted, isFalse);
    });

    test('copyWith preserves untouched fields', () {
      const base = HomeState(hasWallet: true);
      final next = base.copyWith(isLoadingWallet: true);
      expect(next.hasWallet, isTrue);
      expect(next.isLoadingWallet, isTrue);
      expect(next.onboardingCompleted, isFalse);
    });
  });

  group('$SettingsState defaults + copyWith', () {
    test('defaults: en + CHF + mainnet + hideAmounts off', () {
      const state = SettingsState();
      expect(state.language, Language.en);
      expect(state.currency, Currency.chf);
      expect(state.networkMode, NetworkMode.mainnet);
      expect(state.hideAmounts, isFalse);
    });

    test('copyWith preserves untouched fields', () {
      const base = SettingsState(language: Language.de);
      final next = base.copyWith(hideAmounts: true);
      expect(next.language, Language.de);
      expect(next.hideAmounts, isTrue);
      expect(next.currency, Currency.chf);
    });
  });

  group('$SettingsUserDataState equality', () {
    final userData = UserData(
      email: 'a@b.com',
      name: 'Ada Lovelace',
      type: RegistrationUserType.human,
      phoneNumber: '+41',
      birthday: DateTime.utc(1815, 12, 10),
      nationality: const Country(
        id: 41,
        symbol: 'CH',
        name: 'Switzerland',
        kycAllowed: true,
      ),
      addressStreet: 'S',
      addressPostalCode: '8000',
      addressCity: 'Zurich',
      addressCountry: const Country(
        id: 41,
        symbol: 'CH',
        name: 'Switzerland',
        kycAllowed: true,
      ),
      swissTaxResidence: true,
      lang: 'de',
    );

    test('Initial vs Loading distinct, each equals itself', () {
      expect(const SettingsUserDataInitial(), const SettingsUserDataInitial());
      expect(const SettingsUserDataLoading(), const SettingsUserDataLoading());
      expect(const SettingsUserDataInitial(), isNot(const SettingsUserDataLoading()));
    });

    test('Failure equals itself', () {
      expect(
        const SettingsUserDataFailure(),
        const SettingsUserDataFailure(),
      );
      expect(
        const SettingsUserDataFailure(),
        isNot(const SettingsUserDataBitboxDisconnected()),
      );
    });

    test('Success props pin (userData, email, pendingSteps)', () {
      final a = SettingsUserDataSuccess(
        userData: userData,
        email: 'a@b.com',
        pendingSteps: const {KycStepName.contactData},
      );
      final b = SettingsUserDataSuccess(
        userData: userData,
        email: 'a@b.com',
        pendingSteps: const {KycStepName.contactData},
      );
      final c = SettingsUserDataSuccess(
        userData: userData,
        email: 'a@b.com',
        pendingSteps: const {KycStepName.contactData, KycStepName.nationalityData},
      );
      expect(a, b);
      expect(a, isNot(c));
    });

    test('Success defaults: userData/email null, pendingSteps empty', () {
      const state = SettingsUserDataSuccess();
      expect(state.userData, isNull);
      expect(state.email, isNull);
      expect(state.pendingSteps, isEmpty);
    });
  });
}
