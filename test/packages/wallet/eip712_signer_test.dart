import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_credentials.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/packages/wallet/eip712_signer.dart';
import 'package:web3dart/web3dart.dart';

class _StubBitboxCredentials extends BitboxCredentials {
  _StubBitboxCredentials(super.address, this._signature);

  final String _signature;

  @override
  Future<String> signTypedDataV4(int chainId, String jsonData) async => _signature;
}

Future<String> _signWith({
  required CredentialsWithKnownAddress credentials,
}) {
  const country = Country(id: 41, symbol: 'CH', name: 'Switzerland');
  return Eip712Signer.signRegistration(
    credentials: credentials,
    chainId: 1,
    type: 'HUMAN',
    email: 'test-direct@dfx.swiss',
    name: 'Test Direct',
    phoneNumber: '+41791234567',
    birthday: '1990-01-15',
    nationality: country.symbol,
    addressStreet: 'Teststrasse 1',
    addressPostalCode: '8000',
    addressCity: 'Zurich',
    addressCountry: country.symbol,
    swissTaxResidence: true,
    registrationDate: '2025-12-17',
  );
}

void main() {
  group('$Eip712Signer', () {
    test('signs registration data deterministically with EthPrivateKey', () async {
      final credentials = EthPrivateKey.fromHex(
        'fb1ace12f9801e85f3db1b3935dd47d9f064f98152466f47c701b5e12680e612',
      );

      final signature = await _signWith(credentials: credentials);

      expect(
        signature,
        '0xa11cb57186b9c9f9a09fafa7a3aa256ab14ca030d7eba89f35026b64925d617b3e2cb15349ca561fae5e431deed3f1aa69c7d391cfba80aa6111e753fa782ea21c',
      );
    });

    test('throws when BitBox returns an empty signature (cancel mid-sign)', () async {
      // The BitBox iOS bridge returns empty bytes when the user cancels on the
      // device or the BLE link drops mid-sign. Before the guard, the empty
      // signature was POSTed and silently accepted as a successful sign.
      final credentials = _StubBitboxCredentials(
        '0x0000000000000000000000000000000000000000',
        '',
      );

      expect(
        () => _signWith(credentials: credentials),
        throwsA(isA<Exception>()),
      );
    });

    test("throws when BitBox returns '0x' (BLE disconnect mid-sign)", () async {
      final credentials = _StubBitboxCredentials(
        '0x0000000000000000000000000000000000000000',
        '0x',
      );

      expect(
        () => _signWith(credentials: credentials),
        throwsA(isA<Exception>()),
      );
    });
  });
}
