import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/user_dto.dart';

void main() {
  group('$UserKycDto.fromJson', () {
    test('parses hash + level + dataComplete', () {
      final dto = UserKycDto.fromJson({
        'hash': 'abc123',
        'level': 20,
        'dataComplete': true,
      });

      expect(dto.hash, 'abc123');
      expect(dto.level, KycLevel.level20);
      expect(dto.dataComplete, isTrue);
    });

    test('routes level through KycLevelExtension.fromValue', () {
      // The factory delegates the int → enum mapping; pin a non-trivial
      // sentinel so a future regression in the enum mapper is caught here.
      final dto = UserKycDto.fromJson({
        'hash': 'h',
        'level': -10,
        'dataComplete': false,
      });

      expect(dto.level, KycLevel.terminated);
    });
  });

  group('$UserCapabilitiesDto.fromJson', () {
    test('reads all four flags when the API sends them as true', () {
      // Authoritative shape from the API. Every flag false→true flip
      // enables a different UI edit affordance (name / mail / phone /
      // address).
      final dto = UserCapabilitiesDto.fromJson({
        'canEditName': true,
        'canEditMail': true,
        'canEditPhone': true,
        'canEditAddress': true,
      });

      expect(dto.canEditName, isTrue);
      expect(dto.canEditMail, isTrue);
      expect(dto.canEditPhone, isTrue);
      expect(dto.canEditAddress, isTrue);
    });

    test('reads all four flags when the API sends them as false', () {
      final dto = UserCapabilitiesDto.fromJson({
        'canEditName': false,
        'canEditMail': false,
        'canEditPhone': false,
        'canEditAddress': false,
      });

      expect(dto.canEditName, isFalse);
      expect(dto.canEditMail, isFalse);
      expect(dto.canEditPhone, isFalse);
      expect(dto.canEditAddress, isFalse);
    });

    test('missing flag falls back to false (conservative default)', () {
      // Pre-PR backends do not yet ship the capabilities object. Each
      // missing field must default to false so the app does not silently
      // expose actions the API isn't ready to handle.
      final dto = UserCapabilitiesDto.fromJson(<String, dynamic>{});

      expect(dto.canEditName, isFalse);
      expect(dto.canEditMail, isFalse);
      expect(dto.canEditPhone, isFalse);
      expect(dto.canEditAddress, isFalse);
    });

    test('null flag on the wire falls back to false', () {
      // A null value (instead of just missing) must also fold to false —
      // otherwise an `as bool?` cast that succeeds would later throw at
      // first use.
      final dto = UserCapabilitiesDto.fromJson({
        'canEditName': null,
        'canEditMail': null,
        'canEditPhone': null,
        'canEditAddress': null,
      });

      expect(dto.canEditName, isFalse);
      expect(dto.canEditMail, isFalse);
      expect(dto.canEditPhone, isFalse);
      expect(dto.canEditAddress, isFalse);
    });

    test('flags are independent (true/false mix is preserved per field)', () {
      // Pins per-flag wiring — a copy-paste swap inside the factory
      // (canEditName ← canEditMail) would otherwise round-trip uniform
      // payloads without failing.
      final dto = UserCapabilitiesDto.fromJson({
        'canEditName': true,
        'canEditMail': false,
        'canEditPhone': true,
        'canEditAddress': false,
      });

      expect(dto.canEditName, isTrue);
      expect(dto.canEditMail, isFalse);
      expect(dto.canEditPhone, isTrue);
      expect(dto.canEditAddress, isFalse);
    });

    test('const default constructor yields all-false capabilities', () {
      // The default instance is the fallback used when the API does not
      // return a `capabilities` block at all — it must be conservative.
      const dto = UserCapabilitiesDto();

      expect(dto.canEditName, isFalse);
      expect(dto.canEditMail, isFalse);
      expect(dto.canEditPhone, isFalse);
      expect(dto.canEditAddress, isFalse);
    });

    test('preserves all four flags when wire still ships supportAvailable=true', () {
      // PR #588 removed `supportAvailable` from the DTO while the backend
      // still ships the field. The contract is two-sided: the obsolete
      // field is dropped AND the four real flags continue to parse
      // correctly alongside it. Asserting both means the App-PR can ship
      // before the API-PR (DFXswiss/api#3761) without a coordinated cutover.
      final dto = UserCapabilitiesDto.fromJson({
        'canEditName': true,
        'canEditMail': true,
        'canEditPhone': true,
        'canEditAddress': true,
        'supportAvailable': true,
      });

      expect(dto.canEditName, isTrue);
      expect(dto.canEditMail, isTrue);
      expect(dto.canEditPhone, isTrue);
      expect(dto.canEditAddress, isTrue);
    });

    test('preserves all four flags when wire still ships supportAvailable=false', () {
      // Same deploy-order guard, exercising the opposite boolean — the
      // obsolete field must be silently dropped (not coerced into any
      // remaining flag), and the four real flags must still round-trip.
      final dto = UserCapabilitiesDto.fromJson({
        'canEditName': false,
        'canEditMail': false,
        'canEditPhone': false,
        'canEditAddress': false,
        'supportAvailable': false,
      });

      expect(dto.canEditName, isFalse);
      expect(dto.canEditMail, isFalse);
      expect(dto.canEditPhone, isFalse);
      expect(dto.canEditAddress, isFalse);
    });

    test('preserves all four flags when wire still ships supportAvailable=null', () {
      // Some API versions encoded the absence of the value as an explicit
      // null. Covered separately because `as bool? ?? false` and an
      // unknown-key path have different failure modes — the four real
      // flags must round-trip through both.
      final dto = UserCapabilitiesDto.fromJson({
        'canEditName': true,
        'canEditMail': false,
        'canEditPhone': true,
        'canEditAddress': false,
        'supportAvailable': null,
      });

      expect(dto.canEditName, isTrue);
      expect(dto.canEditMail, isFalse);
      expect(dto.canEditPhone, isTrue);
      expect(dto.canEditAddress, isFalse);
    });

    test('preserves all four flags when wire ships arbitrary unknown future keys', () {
      // Generalises the supportAvailable case: every future field the API
      // adds before the app catches up must round-trip without throwing,
      // and the four real flags must continue to parse correctly alongside.
      final dto = UserCapabilitiesDto.fromJson({
        'canEditName': true,
        'canEditMail': false,
        'canEditPhone': true,
        'canEditAddress': false,
        'futureFlagWeAddInOneMonth': 'foo',
        'anotherNumberFlag': 42,
        'nestedObject': {'a': 1},
      });

      expect(dto.canEditName, isTrue);
      expect(dto.canEditMail, isFalse);
      expect(dto.canEditPhone, isTrue);
      expect(dto.canEditAddress, isFalse);
    });
  });

  group('$UserDto.fromJson', () {
    Map<String, dynamic> kycJson() => {
      'hash': 'abc',
      'level': 30,
      'dataComplete': true,
    };

    test('parses the full shape with mail + kyc + capabilities', () {
      final dto = UserDto.fromJson({
        'mail': 'user@example.com',
        'kyc': kycJson(),
        'capabilities': {
          'canEditName': true,
          'canEditMail': false,
          'canEditPhone': true,
          'canEditAddress': false,
        },
      });

      expect(dto.mail, 'user@example.com');
      expect(dto.kyc.hash, 'abc');
      expect(dto.kyc.level, KycLevel.level30);
      expect(dto.kyc.dataComplete, isTrue);
      expect(dto.capabilities.canEditName, isTrue);
      expect(dto.capabilities.canEditMail, isFalse);
    });

    test('mail is optional (null on the wire stays null)', () {
      final dto = UserDto.fromJson({
        'mail': null,
        'kyc': kycJson(),
      });

      expect(dto.mail, isNull);
    });

    test('capabilities absent → falls back to all-false default', () {
      // Branch 1 of the ternary: `json['capabilities'] == null`. Old API
      // backends do not ship capabilities yet — the app must still parse
      // without throwing and render every edit action as disabled.
      final dto = UserDto.fromJson({
        'mail': 'a@b.com',
        'kyc': kycJson(),
        // capabilities missing
      });

      expect(dto.capabilities.canEditName, isFalse);
      expect(dto.capabilities.canEditMail, isFalse);
      expect(dto.capabilities.canEditPhone, isFalse);
      expect(dto.capabilities.canEditAddress, isFalse);
    });

    test('capabilities explicitly null → falls back to all-false default', () {
      // Same default branch but via an explicit `null` (different code
      // path through the `as Map<String, dynamic>` cast guard).
      final dto = UserDto.fromJson({
        'kyc': kycJson(),
        'capabilities': null,
      });

      expect(dto.capabilities.canEditName, isFalse);
    });

    test('capabilities present → parses via $UserCapabilitiesDto.fromJson', () {
      // Branch 2 of the ternary: capabilities object is forwarded
      // verbatim to the nested factory.
      final dto = UserDto.fromJson({
        'kyc': kycJson(),
        'capabilities': {
          'canEditName': false,
          'canEditMail': true,
          'canEditPhone': false,
          'canEditAddress': true,
        },
      });

      expect(dto.capabilities.canEditName, isFalse);
      expect(dto.capabilities.canEditMail, isTrue);
      expect(dto.capabilities.canEditPhone, isFalse);
      expect(dto.capabilities.canEditAddress, isTrue);
    });
  });
}
