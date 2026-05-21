import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_level_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_step_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/kyc/kyc_personal_data.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/real_unit_user_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/user_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/wallet/real_unit_wallet_status_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_wallet_service.dart';
import 'package:realunit_wallet/screens/settings_user_data/cubit/settings_user_data_cubit.dart';

class _MockWalletService extends Mock implements RealUnitWalletService {}

class _MockCountryService extends Mock implements DfxCountryService {}

class _MockKycService extends Mock implements DfxKycService {}

const _ch = Country(id: 41, symbol: 'CH', name: 'Switzerland');
const _de = Country(id: 49, symbol: 'DE', name: 'Germany');

const _address = KycAddress(
  street: 'Teststrasse',
  houseNumber: '1',
  zip: '8000',
  city: 'Zurich',
  country: 41,
);

const _kycData = KycPersonalData(
  accountType: KycAccountType.personal,
  firstName: 'Test',
  lastName: 'User',
  phone: '+41790000000',
  address: _address,
);

RealUnitUserDataDto _userData({
  String nationality = 'CH',
  String addressCountry = 'CH',
}) =>
    RealUnitUserDataDto(
      email: 'a@b.com',
      name: 'Test User',
      type: 'HUMAN',
      phoneNumber: '+41790000000',
      birthday: '1990-01-15',
      nationality: nationality,
      addressStreet: 'Teststrasse 1',
      addressPostalCode: '8000',
      addressCity: 'Zurich',
      addressCountry: addressCountry,
      swissTaxResidence: true,
      lang: 'de',
      kycData: _kycData,
    );

KycStepDto _step(KycStepName name, KycStepStatus status, {int seq = 0}) =>
    KycStepDto(
      name: name,
      status: status,
      sequenceNumber: seq,
      isCurrent: false,
    );

void main() {
  late _MockWalletService walletService;
  late _MockCountryService countryService;
  late _MockKycService kycService;

  setUp(() {
    walletService = _MockWalletService();
    countryService = _MockCountryService();
    kycService = _MockKycService();
  });

  SettingsUserDataCubit build() => SettingsUserDataCubit(
        walletService: walletService,
        countryService: countryService,
        kycService: kycService,
      );

  // Cubit fires getUserData() in its constructor; we assert the final
  // state via stream.firstWhere rather than the full sequence.
  group('$SettingsUserDataCubit', () {
    test('full Success when userData is present and no change steps are pending', () async {
      when(() => walletService.getWalletStatus()).thenAnswer(
        (_) async => RealUnitWalletStatusDto(
          isRegistered: true,
          realUnitUserDataDto: _userData(addressCountry: 'DE'),
        ),
      );
      when(() => kycService.getKycStatus()).thenAnswer(
        (_) async => const KycLevelDto(kycLevel: KycLevel.level20, kycSteps: []),
      );
      when(() => kycService.getUser()).thenAnswer(
        (_) async => const UserDto(
          mail: 'a@b.com',
          kyc: UserKycDto(hash: 'h', level: KycLevel.level20, dataComplete: true),
          capabilities: UserCapabilitiesDto(canEditName: true, canEditAddress: true, canEditPhone: true),
        ),
      );
      when(() => countryService.getCountryBySymbol('CH')).thenAnswer((_) async => _ch);
      when(() => countryService.getCountryBySymbol('DE')).thenAnswer((_) async => _de);

      final cubit = build();
      await cubit.stream.firstWhere((s) => s is SettingsUserDataSuccess);

      final success = cubit.state as SettingsUserDataSuccess;
      expect(success.userData, isNotNull);
      expect(success.userData!.email, 'a@b.com');
      expect(success.userData!.nationality, _ch);
      expect(success.userData!.addressCountry, _de);
      expect(success.pendingSteps, isEmpty);
      expect(success.capabilities.canEditName, isTrue);
    });

    test('Success surfaces pending change steps that are inReview', () async {
      when(() => walletService.getWalletStatus()).thenAnswer(
        (_) async => RealUnitWalletStatusDto(
          isRegistered: true,
          realUnitUserDataDto: _userData(),
        ),
      );
      when(() => kycService.getKycStatus()).thenAnswer(
        (_) async => KycLevelDto(
          kycLevel: KycLevel.level20,
          kycSteps: [
            _step(KycStepName.nameChange, KycStepStatus.inReview),
            _step(KycStepName.addressChange, KycStepStatus.notStarted),
            _step(KycStepName.phoneChange, KycStepStatus.inReview, seq: 1),
            // Non-change-step in review is ignored.
            _step(KycStepName.contactData, KycStepStatus.inReview, seq: 2),
          ],
        ),
      );
      when(() => kycService.getUser()).thenAnswer(
        (_) async => const UserDto(
          mail: 'a@b.com',
          kyc: UserKycDto(hash: 'h', level: KycLevel.level20, dataComplete: true),
        ),
      );
      when(() => countryService.getCountryBySymbol(any())).thenAnswer((_) async => _ch);

      final cubit = build();
      await cubit.stream.firstWhere((s) => s is SettingsUserDataSuccess);

      final success = cubit.state as SettingsUserDataSuccess;
      expect(success.pendingSteps, {KycStepName.nameChange, KycStepName.phoneChange});
    });

    test('userData null + getUser returns mail → Success(email)', () async {
      when(() => walletService.getWalletStatus()).thenAnswer(
        (_) async => RealUnitWalletStatusDto(isRegistered: false),
      );
      when(() => kycService.getKycStatus()).thenAnswer(
        (_) async => const KycLevelDto(kycLevel: KycLevel.level0, kycSteps: []),
      );
      when(() => kycService.getUser()).thenAnswer(
        (_) async => const UserDto(
          mail: 'fallback@b.com',
          kyc: UserKycDto(
            hash: 'h',
            level: KycLevel.level0,
            dataComplete: false,
          ),
        ),
      );

      final cubit = build();
      await cubit.stream.firstWhere((s) => s is SettingsUserDataSuccess);

      final success = cubit.state as SettingsUserDataSuccess;
      expect(success.userData, isNull);
      expect(success.email, 'fallback@b.com');
      // No country lookups when userData is missing.
      verifyNever(() => countryService.getCountryBySymbol(any()));
    });

    test('Failure when walletService.getWalletStatus throws', () async {
      when(() => walletService.getWalletStatus())
          .thenAnswer((_) async => throw Exception('network'));
      when(() => kycService.getKycStatus()).thenAnswer(
        (_) async => const KycLevelDto(kycLevel: KycLevel.level0, kycSteps: []),
      );
      when(() => kycService.getUser()).thenAnswer(
        (_) async => const UserDto(
          mail: 'a@b.com',
          kyc: UserKycDto(hash: 'h', level: KycLevel.level0, dataComplete: false),
        ),
      );

      final cubit = build();
      await cubit.stream.firstWhere((s) => s is SettingsUserDataFailure);

      expect(cubit.state, isA<SettingsUserDataFailure>());
    });

    test('Failure when countryService.getCountryBySymbol throws', () async {
      when(() => walletService.getWalletStatus()).thenAnswer(
        (_) async => RealUnitWalletStatusDto(
          isRegistered: true,
          realUnitUserDataDto: _userData(),
        ),
      );
      when(() => kycService.getKycStatus()).thenAnswer(
        (_) async => const KycLevelDto(kycLevel: KycLevel.level20, kycSteps: []),
      );
      when(() => kycService.getUser()).thenAnswer(
        (_) async => const UserDto(
          mail: 'a@b.com',
          kyc: UserKycDto(hash: 'h', level: KycLevel.level20, dataComplete: true),
        ),
      );
      when(() => countryService.getCountryBySymbol(any()))
          .thenAnswer((_) async => throw Exception('unknown country'));

      final cubit = build();
      await cubit.stream.firstWhere((s) => s is SettingsUserDataFailure);

      expect(cubit.state, isA<SettingsUserDataFailure>());
    });

    test('BitboxDisconnected when BitboxNotConnectedException thrown', () async {
      when(() => walletService.getWalletStatus())
          .thenAnswer((_) async => throw const BitboxNotConnectedException());
      when(() => kycService.getKycStatus()).thenAnswer(
        (_) async => const KycLevelDto(kycLevel: KycLevel.level0, kycSteps: []),
      );
      when(() => kycService.getUser()).thenAnswer(
        (_) async => const UserDto(
          mail: 'a@b.com',
          kyc: UserKycDto(hash: 'h', level: KycLevel.level0, dataComplete: false),
        ),
      );

      final cubit = build();
      await cubit.stream.firstWhere((s) => s is SettingsUserDataBitboxDisconnected);

      expect(cubit.state, isA<SettingsUserDataBitboxDisconnected>());
    });
  });
}
