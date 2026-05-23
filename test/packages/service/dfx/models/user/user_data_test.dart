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

    // The Equatable `props` list intentionally only includes `email` and
    // `name`. The two assertions below pin both branches: identical
    // email+name compares equal (even with differing nationality/phone),
    // and divergent email or name breaks equality. The narrow props
    // surface mirrors that user identity in the app is keyed on the
    // mailbox + display name, not on every detail the API ships.
    test('equality only considers email and name (props are narrow)', () {
      final a = makeUserData(
        phoneNumber: '+41790000001',
        addressStreet: 'A',
      );
      final b = makeUserData(
        phoneNumber: '+41790000002',
        addressStreet: 'B',
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different email or name breaks equality', () {
      final base = makeUserData();
      final differentEmail = makeUserData(email: 'bob@example.com');
      final differentName = makeUserData(name: 'Bob Doe');

      expect(base, isNot(equals(differentEmail)));
      expect(base, isNot(equals(differentName)));
    });

    test('props exposes exactly [email, name]', () {
      // Catches accidental additions to props that would silently widen
      // the equality contract beyond identity (and break the existing
      // call sites that lean on `email == name` matching).
      final data = makeUserData();

      expect(data.props, [data.email, data.name]);
    });
  });
}
