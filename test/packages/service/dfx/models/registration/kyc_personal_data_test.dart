import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/kyc/kyc_personal_data.dart';

void main() {
  group('$KycAddress', () {
    test('toJson serialises country as a nested {id: <int>}', () {
      const address = KycAddress(
        street: 'Bahnhofstrasse',
        houseNumber: '1',
        zip: '8000',
        city: 'Zurich',
        country: 41,
      );

      expect(address.toJson(), {
        'street': 'Bahnhofstrasse',
        'houseNumber': '1',
        'zip': '8000',
        'city': 'Zurich',
        'country': {'id': 41},
      });
    });

    test('toJson omits houseNumber when null', () {
      const address = KycAddress(
        street: 'Bahnhofstrasse',
        zip: '8000',
        city: 'Zurich',
        country: 41,
      );

      final json = address.toJson();
      expect(json.containsKey('houseNumber'), isFalse);
    });

    group('fromJson', () {
      test('reads country as a nested map (the canonical wire shape)', () {
        final address = KycAddress.fromJson({
          'street': 'X',
          'houseNumber': '1',
          'zip': '8000',
          'city': 'Zurich',
          'country': {'id': 41},
        });

        expect(address.country, 41);
        expect(address.houseNumber, '1');
      });

      test('reads country as a bare int (legacy / alternate wire shape)', () {
        // The factory contains a defensive `is Map` check; pin both branches.
        final address = KycAddress.fromJson({
          'street': 'X',
          'zip': '8000',
          'city': 'Zurich',
          'country': 41,
        });

        expect(address.country, 41);
      });

      test('houseNumber is optional (null preserved)', () {
        final address = KycAddress.fromJson({
          'street': 'X',
          'houseNumber': null,
          'zip': '8000',
          'city': 'Zurich',
          'country': {'id': 41},
        });

        expect(address.houseNumber, isNull);
      });
    });
  });

  group('$KycPersonalData', () {
    const baseAddress = KycAddress(
      street: 'Bahnhofstrasse',
      houseNumber: '1',
      zip: '8000',
      city: 'Zurich',
      country: 41,
    );

    test('toJson serialises the personal fields + nested address', () {
      const data = KycPersonalData(
        accountType: KycAccountType.personal,
        firstName: 'Alice',
        lastName: 'Doe',
        phone: '+41790000000',
        address: baseAddress,
      );

      final json = data.toJson();
      expect(json['accountType'], 'Personal');
      expect(json['firstName'], 'Alice');
      expect(json['lastName'], 'Doe');
      expect(json['phone'], '+41790000000');
      expect(json['address'], baseAddress.toJson());
      expect(json.containsKey('organizationName'), isFalse);
      expect(json.containsKey('organizationAddress'), isFalse);
    });

    test('toJson includes organizationName + organizationAddress when set', () {
      const data = KycPersonalData(
        accountType: KycAccountType.organization,
        firstName: 'Alice',
        lastName: 'Doe',
        phone: '+41790000000',
        address: baseAddress,
        organizationName: 'Acme AG',
        organizationAddress: baseAddress,
      );

      final json = data.toJson();
      expect(json['accountType'], 'Organization');
      expect(json['organizationName'], 'Acme AG');
      expect(json['organizationAddress'], baseAddress.toJson());
    });

    test('fromJson round-trips the personal shape', () {
      const original = KycPersonalData(
        accountType: KycAccountType.soleProprietorship,
        firstName: 'A',
        lastName: 'B',
        phone: '+1',
        address: baseAddress,
      );

      final restored = KycPersonalData.fromJson(original.toJson());

      expect(restored.accountType, KycAccountType.soleProprietorship);
      expect(restored.firstName, 'A');
      expect(restored.lastName, 'B');
      expect(restored.phone, '+1');
      expect(restored.address.country, 41);
    });

    test('fromJson preserves the organization fields when present', () {
      const original = KycPersonalData(
        accountType: KycAccountType.organization,
        firstName: 'A',
        lastName: 'B',
        phone: '+1',
        address: baseAddress,
        organizationName: 'Acme',
        organizationAddress: baseAddress,
      );

      final restored = KycPersonalData.fromJson(original.toJson());

      expect(restored.organizationName, 'Acme');
      expect(restored.organizationAddress, isNotNull);
    });
  });

  group('$KycAccountType.fromString', () {
    test('resolves the three known wire values', () {
      expect(KycAccountType.fromString('Personal'), KycAccountType.personal);
      expect(
        KycAccountType.fromString('Organization'),
        KycAccountType.organization,
      );
      expect(
        KycAccountType.fromString('SoleProprietorship'),
        KycAccountType.soleProprietorship,
      );
    });

    test('throws on an unknown value', () {
      expect(() => KycAccountType.fromString('NPO'), throwsException);
    });
  });
}
