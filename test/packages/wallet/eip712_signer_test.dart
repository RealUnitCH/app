import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/wallet/eip712_signer.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  late String privateKeyHex;
  late String email;
  late String name;
  late String phoneNumber;
  late String birthday;
  late String nationality;
  late String addressStreet;
  late String addressPostalCode;
  late String addressCity;
  late String addressCountry;
  late bool swissTaxResidence;
  late String registrationDate;

  group('$EIP712Signer', () {
    test(('sign Registration Data works correctly'), () {
      privateKeyHex = 'fb1ace12f9801e85f3db1b3935dd47d9f064f98152466f47c701b5e12680e612';
      final credentials = EthPrivateKey.fromHex(privateKeyHex);
      final address = credentials.address.hexEip55;
      email = 'test-direct@dfx.swiss';
      name = 'Test Direct';
      phoneNumber = '+41791234567';
      birthday = '1990-01-15';
      nationality = 'CH';
      addressStreet = 'Teststrasse 1';
      addressPostalCode = '8000';
      addressCity = 'Zurich';
      addressCountry = 'CH';
      swissTaxResidence = true;
      registrationDate = '2025-12-17';

      final signature = EIP712Signer.signRegistration(
          privateKey: credentials,
          email: email,
          name: name,
          phoneNumber: phoneNumber,
          birthday: birthday,
          nationality: nationality,
          addressStreet: addressStreet,
          addressPostalCode: addressPostalCode,
          addressCity: addressCity,
          addressCountry: addressCountry,
          swissTaxResidence: swissTaxResidence,
          registrationDate: registrationDate,
          walletAddress: address);

      expect(signature,
          "0xa11cb57186b9c9f9a09fafa7a3aa256ab14ca030d7eba89f35026b64925d617b3e2cb15349ca561fae5e431deed3f1aa69c7d391cfba80aa6111e753fa782ea21c");
    });
  });
}
