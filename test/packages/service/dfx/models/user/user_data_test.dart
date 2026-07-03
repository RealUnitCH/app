import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_user_type.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/user_data.dart';

void main() {
  const switzerland = Country(
    id: 41,
    symbol: 'CH',
    name: 'Switzerland',
    kycAllowed: true,
  );

  const germany = Country(
    id: 49,
    symbol: 'DE',
    name: 'Germany',
    kycAllowed: true,
  );

  UserData makeUserData({
    RegistrationUserType type = RegistrationUserType.human,
    String email = 'alice@example.com',
    String name = 'Alice Doe',
    String phoneNumber = '+41790000000',
    DateTime? birthday,
    Country nationality = switzerland,
    String addressStreet = 'Bahnhofstrasse 1',
    String addressPostalCode = '8000',
    String addressCity = 'Zurich',
    Country addressCountry = switzerland,
    bool swissTaxResidence = true,
    String lang = 'de',
  }) {
    return UserData(
      type: type,
      email: email,
      name: name,
      phoneNumber: phoneNumber,
      birthday: birthday ?? DateTime.utc(1990, 1, 1),
      nationality: nationality,
      addressStreet: addressStreet,
      addressPostalCode: addressPostalCode,
      addressCity: addressCity,
      addressCountry: addressCountry,
      swissTaxResidence: swissTaxResidence,
      lang: lang,
    );
  }

  group('$UserData', () {
    test('stores every constructor field unmodified', () {
      final birthday = DateTime.utc(1985, 6, 15);
      final data = makeUserData(
        type: RegistrationUserType.corporation,
        email: 'corp@example.com',
        name: 'Acme AG',
        phoneNumber: '+41440000000',
        birthday: birthday,
        nationality: germany,
        addressStreet: 'Hauptstrasse 9',
        addressPostalCode: '8001',
        addressCity: 'Bern',
        addressCountry: germany,
        swissTaxResidence: false,
        lang: 'en',
      );

      expect(data.type, RegistrationUserType.corporation);
      expect(data.email, 'corp@example.com');
      expect(data.name, 'Acme AG');
      expect(data.phoneNumber, '+41440000000');
      expect(data.birthday, birthday);
      expect(data.nationality, germany);
      expect(data.addressStreet, 'Hauptstrasse 9');
      expect(data.addressPostalCode, '8001');
      expect(data.addressCity, 'Bern');
      expect(data.addressCountry, germany);
      expect(data.swissTaxResidence, isFalse);
      expect(data.lang, 'en');
    });

    test('instances with identical fields are equal', () {
      final a = makeUserData();
      final b = makeUserData();

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('equality reflects the full field set', () {
      final base = makeUserData();

      expect(base, isNot(equals(makeUserData(email: 'bob@example.com'))));
      expect(base, isNot(equals(makeUserData(name: 'Bob Doe'))));
      expect(base, isNot(equals(makeUserData(type: RegistrationUserType.corporation))));
      expect(base, isNot(equals(makeUserData(phoneNumber: '+41790000009'))));
      expect(base, isNot(equals(makeUserData(nationality: germany))));
      expect(base, isNot(equals(makeUserData(addressStreet: 'Other 2'))));
      expect(base, isNot(equals(makeUserData(addressPostalCode: '9999'))));
      expect(base, isNot(equals(makeUserData(addressCity: 'Geneva'))));
      expect(base, isNot(equals(makeUserData(addressCountry: germany))));
      expect(base, isNot(equals(makeUserData(swissTaxResidence: false))));
      expect(base, isNot(equals(makeUserData(lang: 'en'))));
      expect(base, isNot(equals(makeUserData(birthday: DateTime.utc(1991, 2, 3)))));
    });
  });
}
