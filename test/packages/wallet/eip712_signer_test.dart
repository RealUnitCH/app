import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_credentials.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_user_type.dart';
import 'package:realunit_wallet/packages/wallet/eip712_signer.dart';
import 'package:realunit_wallet/packages/wallet/exceptions/signing_cancelled_exception.dart';
import 'package:web3dart/web3dart.dart';

class _MockBitboxCredentials extends Mock implements BitboxCredentials {}

Future<String> _signWith(BitboxCredentials credentials) => Eip712Signer.signRegistration(
  credentials: credentials,
  chainId: 1,
  type: RegistrationUserType.human.jsonName,
  email: 'cancel@dfx.swiss',
  name: 'Cancel User',
  phoneNumber: '+41790000000',
  birthday: '1990-01-01',
  nationality: 'CH',
  addressStreet: 'Teststrasse 1',
  addressPostalCode: '8000',
  addressCity: 'Zurich',
  addressCountry: 'CH',
  swissTaxResidence: true,
  registrationDate: '2026-05-12',
);

void main() {
  late String privateKeyHex;
  late RegistrationUserType type;
  late String email;
  late String firstName;
  late String lastName;
  late String phoneNumber;
  late String birthday;
  late Country nationality;
  late String addressStreet;
  late String addressStreetNumber;
  late String addressPostalCode;
  late String addressCity;
  late Country addressCountry;
  late bool swissTaxResidence;
  late String registrationDate;

  group('$Eip712Signer', () {
    test(('sign Registration Data works correctly'), () async {
      privateKeyHex = 'fb1ace12f9801e85f3db1b3935dd47d9f064f98152466f47c701b5e12680e612';
      final credentials = EthPrivateKey.fromHex(privateKeyHex);
      type = RegistrationUserType.human;
      email = 'test-direct@dfx.swiss';
      firstName = 'Test';
      lastName = 'Direct';
      phoneNumber = '+41791234567';
      birthday = '1990-01-15';
      nationality = const Country(id: 41, symbol: 'CH', name: 'Switzerland');
      addressStreet = 'Teststrasse';
      addressStreetNumber = '1';
      addressPostalCode = '8000';
      addressCity = 'Zurich';
      addressCountry = const Country(id: 41, symbol: 'CH', name: 'Switzerland');
      swissTaxResidence = true;
      registrationDate = '2025-12-17';

      final registration = Registration(
        type: type,
        email: email,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        birthday: birthday,
        nationality: nationality,
        addressStreet: addressStreet,
        addressStreetNumber: addressStreetNumber,
        addressPostalCode: addressPostalCode,
        addressCity: addressCity,
        addressCountry: addressCountry,
        swissTaxResidence: swissTaxResidence,
      );

      final signature = await Eip712Signer.signRegistration(
        credentials: credentials,
        chainId: 1,
        type: registration.type.jsonName,
        email: registration.email,
        name: '${registration.firstName} ${registration.lastName}',
        phoneNumber: registration.phoneNumber,
        birthday: registration.birthday,
        nationality: registration.nationality.symbol,
        addressStreet: '${registration.addressStreet} ${registration.addressStreetNumber}',
        addressPostalCode: registration.addressPostalCode,
        addressCity: registration.addressCity,
        addressCountry: registration.addressCountry.symbol,
        swissTaxResidence: registration.swissTaxResidence,
        registrationDate: registrationDate,
      );

      expect(
        signature,
        '0xa11cb57186b9c9f9a09fafa7a3aa256ab14ca030d7eba89f35026b64925d617b3e2cb15349ca561fae5e431deed3f1aa69c7d391cfba80aa6111e753fa782ea21c',
      );
    });

    for (final emptySignature in const ['', '0x']) {
      test('throws SigningCancelledException when BitBox returns "$emptySignature"', () async {
        final credentials = _MockBitboxCredentials();
        when(
          () => credentials.address,
        ).thenReturn(EthereumAddress.fromHex('0x0000000000000000000000000000000000000001'));
        when(
          () => credentials.signTypedDataV4(any(), any()),
        ).thenAnswer((_) async => emptySignature);

        expect(() => _signWith(credentials), throwsA(isA<SigningCancelledException>()));
      });
    }
  });
}
