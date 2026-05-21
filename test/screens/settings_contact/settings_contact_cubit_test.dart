import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_company_info_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/company_info/dto/dfx_company_info_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/user_dto.dart';
import 'package:realunit_wallet/screens/settings_contact/cubit/settings_contact_cubit.dart';

class _MockKycService extends Mock implements DfxKycService {}

class _MockCompanyInfoService extends Mock implements DfxCompanyInfoService {}

UserDto _user({String? mail, bool supportAvailable = false}) => UserDto(
      mail: mail,
      kyc: const UserKycDto(hash: 'h', level: KycLevel.level0, dataComplete: false),
      capabilities: UserCapabilitiesDto(supportAvailable: supportAvailable),
    );

const _realUnitInfo = DfxCompanyInfoDto(
  brand: 'RealUnit',
  name: 'RealUnit Schweiz AG',
  phone: '+41 41 761 00 90',
  email: 'info@realunit.ch',
  website: 'realunit.ch',
  address: DfxCompanyInfoAddressDto(
    street: 'Schochenmühlestrasse 6',
    zip: '6340',
    city: 'Baar',
    country: 'CH',
  ),
);

void main() {
  late _MockKycService kyc;
  late _MockCompanyInfoService companyInfo;

  setUp(() {
    kyc = _MockKycService();
    companyInfo = _MockCompanyInfoService();
    when(() => companyInfo.getForBrand(any())).thenAnswer((_) async => _realUnitInfo);
  });

  group('$SettingsContactCubit', () {
    test('Success carries supportAvailable + company-info when both calls succeed', () async {
      when(() => kyc.getUser())
          .thenAnswer((_) async => _user(mail: 'a@b.com', supportAvailable: true));

      final cubit = SettingsContactCubit(kyc, companyInfo);
      await cubit.stream.firstWhere((s) => s is SettingsContactSuccess);

      final state = cubit.state as SettingsContactSuccess;
      expect(state.supportAvailable, isTrue);
      expect(state.companyInfo, isNotNull);
      expect(state.companyInfo!.brand, 'RealUnit');
      expect(state.companyInfo!.phone, contains('+41'));
      verify(() => kyc.getUser()).called(1);
      verify(() => companyInfo.getForBrand('RealUnit')).called(1);
    });

    test('reaches Success(supportAvailable: false) when API capability flag is false', () async {
      when(() => kyc.getUser())
          .thenAnswer((_) async => _user(mail: null, supportAvailable: false));

      final cubit = SettingsContactCubit(kyc, companyInfo);
      await cubit.stream.firstWhere((s) => s is SettingsContactSuccess);

      expect((cubit.state as SettingsContactSuccess).supportAvailable, isFalse);
    });

    test('Failure when getUser throws', () async {
      when(() => kyc.getUser()).thenAnswer((_) async => throw Exception('boom'));

      final cubit = SettingsContactCubit(kyc, companyInfo);
      await cubit.stream.firstWhere((s) => s is SettingsContactFailure);

      expect((cubit.state as SettingsContactFailure).message, contains('boom'));
    });

    test(
      'Success(companyInfo=null) when only company-info lookup throws — getUser ok ⇒ Support-Tile bleibt sichtbar',
      () async {
        when(() => kyc.getUser())
            .thenAnswer((_) async => _user(mail: 'a@b.com', supportAvailable: true));
        when(
          () => companyInfo.getForBrand(any()),
        ).thenAnswer((_) async => throw Exception('no brand'));

        final cubit = SettingsContactCubit(kyc, companyInfo);
        await cubit.stream.firstWhere((s) => s is SettingsContactSuccess);

        final state = cubit.state as SettingsContactSuccess;
        expect(state.supportAvailable, isTrue);
        expect(
          state.companyInfo,
          isNull,
          reason:
              'Teilausfall: Support-Tile rendert via supportAvailable, Impressum/Phone/Mail-Block via null-Guard',
        );
      },
    );

    test('getUser + companyInfo werden parallel angestossen', () async {
      // Wenn beide Calls sequentiell laufen würden, müsste companyInfo
      // erst nach Auflösung von getUser starten. Wir simulieren einen
      // langsamen getUser und einen schnellen companyInfo und prüfen,
      // dass companyInfo nicht auf getUser warten musste.
      final userCompleter = Completer<UserDto>();
      var companyInfoCalled = false;
      when(() => kyc.getUser()).thenAnswer((_) => userCompleter.future);
      when(() => companyInfo.getForBrand(any())).thenAnswer((_) async {
        companyInfoCalled = true;
        return _realUnitInfo;
      });

      final cubit = SettingsContactCubit(kyc, companyInfo);
      // Microtask-Queue durchlaufen lassen, damit beide Futures starten.
      await Future<void>.delayed(Duration.zero);
      expect(
        companyInfoCalled,
        isTrue,
        reason: 'companyInfo muss starten bevor getUser auflöst',
      );

      userCompleter.complete(_user(mail: 'a@b.com', supportAvailable: true));
      await cubit.stream.firstWhere((s) => s is SettingsContactSuccess);

      expect((cubit.state as SettingsContactSuccess).supportAvailable, isTrue);
      expect((cubit.state as SettingsContactSuccess).companyInfo, isNotNull);
    });

    test('manual init() call after a failure recovers to Success', () async {
      var calls = 0;
      when(() => kyc.getUser()).thenAnswer((_) async {
        calls++;
        if (calls == 1) throw Exception('transient');
        return _user(mail: 'recovered@b.com', supportAvailable: true);
      });

      final cubit = SettingsContactCubit(kyc, companyInfo);
      await cubit.stream.firstWhere((s) => s is SettingsContactFailure);
      await cubit.init();

      expect(cubit.state, isA<SettingsContactSuccess>());
      expect((cubit.state as SettingsContactSuccess).supportAvailable, isTrue);
    });
  });
}
