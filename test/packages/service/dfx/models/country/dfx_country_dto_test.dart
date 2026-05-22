import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/dto/dfx_country_dto.dart';

Map<String, dynamic> _wire({
  String? foreignName,
  bool ibanAllowed = true,
  bool locationAllowed = true,
  bool nationalityAllowed = true,
}) => {
  'id': 41,
  'symbol': 'CH',
  'name': 'Switzerland',
  'foreignName': foreignName,
  'locationAllowed': locationAllowed,
  'ibanAllowed': ibanAllowed,
  'kycAllowed': true,
  'kycOrganizationAllowed': true,
  'nationalityAllowed': nationalityAllowed,
  'bankAllowed': true,
  'cardAllowed': true,
  'cryptoAllowed': true,
};

void main() {
  group('$DfxCountryDto.fromJson', () {
    test('maps every field from the wire', () {
      final dto = DfxCountryDto.fromJson(_wire(foreignName: 'Schweiz'));

      expect(dto.id, 41);
      expect(dto.symbol, 'CH');
      expect(dto.name, 'Switzerland');
      expect(dto.foreignName, 'Schweiz');
      expect(dto.locationAllowed, isTrue);
      expect(dto.ibanAllowed, isTrue);
      expect(dto.kycAllowed, isTrue);
      expect(dto.kycOrganizationAllowed, isTrue);
      expect(dto.nationalityAllowed, isTrue);
      expect(dto.bankAllowed, isTrue);
      expect(dto.cardAllowed, isTrue);
      expect(dto.cryptoAllowed, isTrue);
    });

    test('foreignName is optional (null on the wire stays null)', () {
      final dto = DfxCountryDto.fromJson(_wire(foreignName: null));

      expect(dto.foreignName, isNull);
    });

    test('boolean false flags are preserved (not coerced)', () {
      final dto = DfxCountryDto.fromJson(_wire(ibanAllowed: false));

      expect(dto.ibanAllowed, isFalse);
    });
  });

  group('DfxCountryDtoMapper.toCountry', () {
    test('keeps id / symbol / name / foreignName and the purpose allow-flags', () {
      final country = DfxCountryDto.fromJson(_wire(foreignName: 'Schweiz')).toCountry();

      expect(country, isA<Country>());
      expect(country.id, 41);
      expect(country.symbol, 'CH');
      expect(country.name, 'Switzerland');
      expect(country.foreignName, 'Schweiz');
      expect(country.nationalityAllowed, isTrue);
      expect(country.locationAllowed, isTrue);
    });

    test('passes false allow-flags through unchanged', () {
      final country = DfxCountryDto.fromJson(
        _wire(nationalityAllowed: false, locationAllowed: false),
      ).toCountry();

      expect(country.nationalityAllowed, isFalse);
      expect(country.locationAllowed, isFalse);
    });
  });

  group('$Country equality', () {
    test('two Country instances with the same id are ==', () {
      const a = Country(
        id: 41,
        symbol: 'CH',
        name: 'Switzerland',
        nationalityAllowed: true,
        locationAllowed: true,
      );
      const b = Country(
        id: 41,
        symbol: 'XX',
        name: 'Different name',
        foreignName: 'F',
        nationalityAllowed: false,
        locationAllowed: false,
      );

      // Equality only on id (props returns [id]).
      expect(a, equals(b));
    });

    test('different ids → different equality', () {
      const a = Country(
        id: 41,
        symbol: 'CH',
        name: 'Switzerland',
        nationalityAllowed: true,
        locationAllowed: true,
      );
      const b = Country(
        id: 49,
        symbol: 'DE',
        name: 'Germany',
        nationalityAllowed: true,
        locationAllowed: true,
      );

      expect(a, isNot(equals(b)));
    });
  });
}
