import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dto/real_unit_registration_email_request_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dto/real_unit_registration_email_response_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dto/real_unit_registration_register_wallet_request_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dto/real_unit_registration_request_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dto/real_unit_registration_response_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/kyc/kyc_personal_data.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_email_status.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_status.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_user_type.dart';

import '../../../../../helper/pump_app.dart';

void main() {
  group('$RegistrationEmailStatus.fromString', () {
    test('parses email_registered', () {
      expect(
        RegistrationEmailStatus.fromString('email_registered'),
        RegistrationEmailStatus.emailRegistered,
      );
    });

    test('parses merge_requested', () {
      expect(
        RegistrationEmailStatus.fromString('merge_requested'),
        RegistrationEmailStatus.mergeRequested,
      );
    });

    test('throws on unknown values', () {
      expect(() => RegistrationEmailStatus.fromString('weird'), throwsException);
    });
  });

  group('$RegistrationStatus.fromString', () {
    test('parses completed', () {
      expect(RegistrationStatus.fromString('completed'), RegistrationStatus.completed);
    });

    test('parses pending_review', () {
      expect(
        RegistrationStatus.fromString('pending_review'),
        RegistrationStatus.pendingReview,
      );
    });

    test('parses forwarding_failed', () {
      expect(
        RegistrationStatus.fromString('forwarding_failed'),
        RegistrationStatus.forwardingFailed,
      );
    });

    test('throws on unknown values', () {
      expect(() => RegistrationStatus.fromString('mystery'), throwsException);
    });
  });

  group('$RegistrationUserType.fromName', () {
    test('parses HUMAN', () {
      expect(
        RegistrationUserType.fromName('HUMAN'),
        RegistrationUserType.human,
      );
    });

    test('parses CORPORATION', () {
      expect(
        RegistrationUserType.fromName('CORPORATION'),
        RegistrationUserType.corporation,
      );
    });

    test('throws ArgumentError on unknown names', () {
      expect(
        () => RegistrationUserType.fromName('alien'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  // `name(BuildContext)` is a switch over the two enum values that
  // resolves a localized label via `S.of(context)`. Both arms must hit
  // a non-empty distinct string so the registration screen does not show
  // "Human" for corporations or vice versa.
  group('$RegistrationUserType.name(BuildContext)', () {
    testWidgets('human resolves to a non-empty localized label', (tester) async {
      String? label;
      await tester.pumpApp(
        Builder(
          builder: (context) {
            label = RegistrationUserType.human.name(context);
            return const SizedBox.shrink();
          },
        ),
      );

      expect(label, isNotNull);
      expect(label, isNotEmpty);
    });

    testWidgets('corporation resolves to a non-empty label distinct from human', (tester) async {
      String? human;
      String? corporation;
      await tester.pumpApp(
        Builder(
          builder: (context) {
            human = RegistrationUserType.human.name(context);
            corporation = RegistrationUserType.corporation.name(context);
            return const SizedBox.shrink();
          },
        ),
      );

      expect(corporation, isNotNull);
      expect(corporation, isNotEmpty);
      expect(corporation, isNot(equals(human)));
    });
  });

  group('$RealUnitEmailRegistrationRequestDto.toJson', () {
    test('wraps the email in a single-key object', () {
      const dto = RealUnitEmailRegistrationRequestDto(email: 'a@b.com');

      expect(dto.toJson(), {'email': 'a@b.com'});
    });
  });

  group('$RealUnitRegisterWalletRequestDto.toJson', () {
    test('serialises walletAddress + signature + registrationDate', () {
      const dto = RealUnitRegisterWalletRequestDto(
        walletAddress: '0xwallet',
        signature: '0xsig',
        registrationDate: '2026-05-15T10:00:00Z',
      );

      expect(dto.toJson(), {
        'walletAddress': '0xwallet',
        'signature': '0xsig',
        'registrationDate': '2026-05-15T10:00:00Z',
      });
    });
  });

  group('$RealUnitRegistrationEmailResponseDto.fromJson', () {
    test('reads status via $RegistrationEmailStatus.fromString', () {
      final dto = RealUnitRegistrationEmailResponseDto.fromJson({
        'status': 'email_registered',
      });

      expect(dto.status, RegistrationEmailStatus.emailRegistered);
    });

    test('propagates the exception on an unknown status', () {
      expect(
        () => RealUnitRegistrationEmailResponseDto.fromJson({'status': 'nope'}),
        throwsException,
      );
    });
  });

  group('$RealUnitRegistrationResponseDto.fromJson', () {
    test('reads status via $RegistrationStatus.fromString', () {
      final dto = RealUnitRegistrationResponseDto.fromJson({'status': 'completed'});

      expect(dto.status, RegistrationStatus.completed);
    });

    test('propagates the exception on an unknown status', () {
      expect(
        () => RealUnitRegistrationResponseDto.fromJson({'status': 'weird'}),
        throwsException,
      );
    });
  });

  group('$CountryAndTin', () {
    test('fromJson + toJson round-trip', () {
      const json = {'country': 'CH', 'tin': '756.1234.5678.97'};
      final dto = CountryAndTin.fromJson(json);

      expect(dto.country, 'CH');
      expect(dto.tin, '756.1234.5678.97');
      expect(dto.toJson(), json);
    });
  });

  group('$RealUnitRegistrationRequestDto.toJson', () {
    const kycData = KycPersonalData(
      accountType: KycAccountType.personal,
      firstName: 'Ada',
      lastName: 'Lovelace',
      phone: '+41 79 000 00 00',
      address: KycAddress(
        street: 'Bahnhofstrasse',
        houseNumber: '1',
        zip: '8000',
        city: 'Zurich',
        country: 41,
      ),
    );

    RealUnitRegistrationRequestDto build({List<CountryAndTin>? tins}) =>
        RealUnitRegistrationRequestDto(
          type: RegistrationUserType.human.jsonName,
          email: 'a@b.com',
          name: 'Ada Lovelace',
          phoneNumber: '+41 79 000 00 00',
          birthday: '1815-12-10',
          nationality: 'CH',
          addressStreet: 'Bahnhofstrasse 1',
          addressPostalCode: '8000',
          addressCity: 'Zurich',
          addressCountry: 'CH',
          swissTaxResidence: true,
          registrationDate: '2026-05-15T10:00:00Z',
          walletAddress: '0xwallet',
          signature: '0xsig',
          lang: 'de',
          kycData: kycData,
          countryAndTINs: tins,
        );

    test('omits countryAndTINs when null', () {
      final json = build().toJson();

      expect(json.containsKey('countryAndTINs'), isFalse);
      expect(json['type'], 'HUMAN');
      expect(json['kycData'], kycData.toJson());
      expect(json['lang'], 'de');
      expect(json['swissTaxResidence'], isTrue);
    });

    test('includes countryAndTINs when provided', () {
      final json = build(
        tins: const [
          CountryAndTin(country: 'CH', tin: '111'),
          CountryAndTin(country: 'DE', tin: '222'),
        ],
      ).toJson();

      final tins = json['countryAndTINs'] as List<dynamic>;
      expect(tins, hasLength(2));
      expect(tins.first, {'country': 'CH', 'tin': '111'});
    });
  });
}
