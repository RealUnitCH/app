// We deliberately use non-const constructors throughout this file so the
// generative constructor lines get counted as executed in the coverage
// report. Const-only construction is a compile-time optimisation and is
// not visible to the line-coverage instrumentation.
// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_user_type.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/user_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/user_data.dart';
import 'package:realunit_wallet/screens/settings_user_data/cubit/settings_user_data_cubit.dart';

/// Equatable-`props` surface tests for `SettingsUserDataState`.
UserData _userData() => UserData(
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

void main() {
  group('SettingsUserDataInitial', () {
    test('two instances are equal and props are empty', () {
      final a = SettingsUserDataInitial();
      final b = SettingsUserDataInitial();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.props, isEmpty);
    });
  });

  group('SettingsUserDataLoading', () {
    test('two instances are equal and props are empty', () {
      final a = SettingsUserDataLoading();
      final b = SettingsUserDataLoading();
      expect(a, equals(b));
      expect(a.props, isEmpty);
    });
  });

  group('SettingsUserDataFailure', () {
    test('two instances are equal and props are empty', () {
      final a = SettingsUserDataFailure();
      final b = SettingsUserDataFailure();
      expect(a, equals(b));
      expect(a.props, isEmpty);
    });
  });

  group('SettingsUserDataBitboxDisconnected', () {
    test('two instances are equal and props are empty', () {
      final a = SettingsUserDataBitboxDisconnected();
      final b = SettingsUserDataBitboxDisconnected();
      expect(a, equals(b));
      expect(a.props, isEmpty);
    });
  });

  group('SettingsUserDataSuccess', () {
    test('defaults: nulls + empty steps + default capabilities', () {
      final state = SettingsUserDataSuccess();
      expect(state.userData, isNull);
      expect(state.email, isNull);
      expect(state.pendingSteps, isEmpty);
      expect(state.capabilities, isA<UserCapabilitiesDto>());
    });

    test('same payload is equal and props match', () {
      final ud = _userData();
      final a = SettingsUserDataSuccess(
        userData: ud,
        email: 'a@b.com',
        pendingSteps: const {KycStepName.contactData},
      );
      final b = SettingsUserDataSuccess(
        userData: ud,
        email: 'a@b.com',
        pendingSteps: const {KycStepName.contactData},
      );
      expect(a, equals(b));
      expect(a.props.length, 4);
    });

    test('different pendingSteps is unequal', () {
      final ud = _userData();
      final a = SettingsUserDataSuccess(
        userData: ud,
        email: 'a@b.com',
        pendingSteps: const {KycStepName.contactData},
      );
      final b = SettingsUserDataSuccess(
        userData: ud,
        email: 'a@b.com',
        pendingSteps: const {KycStepName.contactData, KycStepName.nationalityData},
      );
      expect(a, isNot(equals(b)));
    });

    test('different capabilities is unequal', () {
      final ud = _userData();
      final a = SettingsUserDataSuccess(
        userData: ud,
        capabilities: const UserCapabilitiesDto(),
      );
      final b = SettingsUserDataSuccess(
        userData: ud,
        capabilities: const UserCapabilitiesDto(canEditAddress: true),
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('SettingsUserDataState (cross-subclass identity)', () {
    test('Initial vs Loading vs Failure vs BitboxDisconnected are all distinct', () {
      // All four inherit `props => []`. Equatable's runtimeType check
      // separates them.
      final i = SettingsUserDataInitial();
      final l = SettingsUserDataLoading();
      final f = SettingsUserDataFailure();
      final d = SettingsUserDataBitboxDisconnected();
      expect(i, isNot(equals(l)));
      expect(l, isNot(equals(f)));
      expect(f, isNot(equals(d)));
      expect(i, isNot(equals(d)));
    });
  });
}
