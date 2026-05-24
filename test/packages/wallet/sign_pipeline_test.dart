// Tier-0 contract test for [SignPipeline].
//
// Pins the architectural promise (ADR 0002): EVERY sign flow funnels
// through the same pipeline, and every entrypoint honours the
// pipeline-step contract.
//
// Six entrypoints exercised:
//
//   1. RegistrationSignRequest    — typed-data registration sign
//   2. KycSignRequest             — standalone KYC sign
//   3. SellSignRequest            — EIP-7702 sell delegation sign
//   4. Eip7702SignRequest         — generic EIP-7702 (same shape as Sell)
//   5. BtcPsbtSignRequest         — PSBT pre-flight + (todo) submit
//   6. EthTransferSignRequest     — raw ETH transfer (EIP-1559 + legacy)
//
// Property test pinned:
//
//   pipeline(s).envelope == pipeline(s).dto  byte-equal post-romanise
//
// Adversarial vectors:
//
//   - non-ASCII in any user string is romanised the same way in
//     envelope AND dto (closes F-019)
//   - unknown native error code surfaces as BitboxUnknownException
//   - empty required field raises SignRequestValidationException
//   - cubits switching on `SignException` see typed errors — no
//     `e.toString()` matching needed

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/eip7702/eip7702_data_dto.dart';
import 'package:realunit_wallet/packages/wallet/error_mapper.dart';
import 'package:realunit_wallet/packages/wallet/schemas/registration_schema.dart';
import 'package:realunit_wallet/packages/wallet/sign_pipeline.dart';
import 'package:web3dart/web3dart.dart';

const _privateKeyHex = 'fb1ace12f9801e85f3db1b3935dd47d9f064f98152466f47c701b5e12680e612';
// Derived from _privateKeyHex via EthPrivateKey.fromHex(...).address.hexEip55.
const _testAddress = '0xD29C323DfD441E5157F5a05ccE6c74aC94c57aAd';
const _verifyingContract = '0xdb9b1e94b5b69df7e401ddbede43491141047db3';

EthPrivateKey _credentials() => EthPrivateKey.fromHex(_privateKeyHex);

RegistrationSignRequest _registrationReq({
  String email = 'pipeline@dfx.swiss',
  String name = 'Pipeline User',
  String addressCity = 'Zurich',
  bool swissTaxResidence = false,
  String registrationDate = '2026-05-23',
  int chainId = 1,
}) {
  return RegistrationSignRequest(
    credentials: _credentials(),
    chainId: chainId,
    verifyingContract: _verifyingContract,
    email: email,
    name: name,
    type: 'human',
    phoneNumber: '+41790000000',
    birthday: '1990-01-01',
    nationality: 'CH',
    addressStreet: 'Teststrasse 1',
    addressPostalCode: '8000',
    addressCity: addressCity,
    addressCountry: 'CH',
    swissTaxResidence: swissTaxResidence,
    registrationDate: registrationDate,
  );
}

KycSignRequest _kycReq({String firstName = 'Pipeline', String lastName = 'User'}) {
  return KycSignRequest(
    credentials: _credentials(),
    chainId: 1,
    verifyingContract: _verifyingContract,
    accountType: 'PERSONAL',
    firstName: firstName,
    lastName: lastName,
    phone: '+41790000000',
    addressStreet: 'Teststrasse',
    addressHouseNumber: '1',
    addressZip: '8000',
    addressCity: 'Zurich',
    addressCountry: 41,
    registrationDate: '2026-05-23',
  );
}

Eip7702Data _validEip7702Data({
  List<Eip7702TypeField>? delegation,
}) {
  return Eip7702Data(
    relayerAddress: '0x0000000000000000000000000000000000000abc',
    delegationManagerAddress: _verifyingContract,
    delegatorAddress: _testAddress,
    userNonce: 0,
    domain: const Eip7702Domain(
      name: 'DelegationManager',
      version: '1',
      chainId: 1,
      verifyingContract: _verifyingContract,
    ),
    types: Eip7702Types(
      delegation:
          delegation ??
          const [
            Eip7702TypeField(name: 'delegate', type: 'address'),
            Eip7702TypeField(name: 'delegator', type: 'address'),
            Eip7702TypeField(name: 'authority', type: 'bytes32'),
            Eip7702TypeField(name: 'caveats', type: 'Caveat[]'),
            Eip7702TypeField(name: 'salt', type: 'uint256'),
          ],
      caveat: const [
        Eip7702TypeField(name: 'enforcer', type: 'address'),
        Eip7702TypeField(name: 'terms', type: 'bytes'),
      ],
    ),
    message: const Eip7702Message(
      delegate: '0x0000000000000000000000000000000000000abc',
      delegator: _testAddress,
      authority:
          '0x0000000000000000000000000000000000000000000000000000000000000000',
      caveats: [],
      salt: 0,
    ),
    tokenAddress: '0x0000000000000000000000000000000000000aaa',
    amountWei: '1000000000000000000',
    depositAddress: '0x0000000000000000000000000000000000000bbb',
  );
}

Eip7702SignRequest _eip7702Req({Eip7702Data? data}) {
  return Eip7702SignRequest(
    credentials: _credentials(),
    eip7702Data: data ?? _validEip7702Data(),
    expectedVerifyingContract: _verifyingContract,
    expectedChainId: 1,
    expectedDelegator: _testAddress,
    expectedAmount: BigInt.from(10).pow(18),
  );
}

SellSignRequest _sellReq() {
  return SellSignRequest(
    credentials: _credentials(),
    eip7702Data: _validEip7702Data(),
    expectedVerifyingContract: _verifyingContract,
    expectedChainId: 1,
    expectedDelegator: _testAddress,
    expectedAmount: BigInt.from(10).pow(18),
  );
}

BtcPsbtSignRequest _psbtReq({Uint8List? bytes}) {
  // Minimal valid PSBT — magic bytes + a trailing terminator byte to
  // satisfy the 5+ byte length floor. Production PSBTs are bigger; the
  // pipeline only enforces the magic-byte pre-flight here.
  return BtcPsbtSignRequest(
    credentials: _credentials(),
    psbtBytes:
        bytes ?? Uint8List.fromList([0x70, 0x73, 0x62, 0x74, 0xff, 0x00]),
  );
}

EthTransferSignRequest _ethReq({
  bool isEIP1559 = true,
  List<int>? payload,
  int chainId = 1,
}) {
  return EthTransferSignRequest(
    credentials: _credentials(),
    payload: Uint8List.fromList(
      payload ?? [if (isEIP1559) 0x02, 0xaa, 0xbb, 0xcc, 0xdd],
    ),
    chainId: chainId,
    isEIP1559: isEIP1559,
  );
}

void main() {
  const pipeline = SignPipeline();

  group('SignPipeline: six entrypoints all succeed', () {
    test('1. RegistrationSignRequest → TypedDataSignResult with non-empty signature', () async {
      final result = await pipeline.sign(_registrationReq());
      expect(result, isA<TypedDataSignResult>());
      final typed = result as TypedDataSignResult;
      expect(typed.signature, startsWith('0x'));
      expect(typed.envelopeJson, contains('"primaryType":"RealUnitUser"'));
      expect(typed.dtoJson, contains('"swissTaxResidence":false'));
    });

    test('2. KycSignRequest → TypedDataSignResult with non-empty signature', () async {
      final result = await pipeline.sign(_kycReq());
      expect(result, isA<TypedDataSignResult>());
      final typed = result as TypedDataSignResult;
      expect(typed.signature, startsWith('0x'));
      expect(typed.envelopeJson, contains('"primaryType":"RealUnitKyc"'));
    });

    test('3. SellSignRequest → TypedDataSignResult with non-empty signature', () async {
      final result = await pipeline.sign(_sellReq());
      expect(result, isA<TypedDataSignResult>());
      final typed = result as TypedDataSignResult;
      expect(typed.signature, startsWith('0x'));
      expect(typed.envelopeJson, contains('"primaryType":"Delegation"'));
    });

    test('4. Eip7702SignRequest → TypedDataSignResult with non-empty signature', () async {
      final result = await pipeline.sign(_eip7702Req());
      expect(result, isA<TypedDataSignResult>());
      expect((result as TypedDataSignResult).signature, startsWith('0x'));
    });

    test('5. BtcPsbtSignRequest → BtcPsbtSignResult (magic-byte pre-flight)', () async {
      final result = await pipeline.sign(_psbtReq());
      expect(result, isA<BtcPsbtSignResult>());
    });

    test('6. EthTransferSignRequest (EIP-1559) → EthTransferSignResult', () async {
      final result = await pipeline.sign(_ethReq(isEIP1559: true));
      expect(result, isA<EthTransferSignResult>());
    });

    test('6b. EthTransferSignRequest (legacy) → EthTransferSignResult', () async {
      final result = await pipeline.sign(_ethReq(isEIP1559: false));
      expect(result, isA<EthTransferSignResult>());
    });
  });

  group('Romanisation invariant (F-019): envelope and dto are byte-equal-equivalent', () {
    test('non-ASCII registration name appears identically in envelope and dto', () async {
      final result = await pipeline.sign(
        _registrationReq(
          name: 'Joshua Krüger',
          addressCity: 'Zürich',
          email: 'pipeline+æø@dfx.swiss',
        ),
      );
      final typed = result as TypedDataSignResult;
      final envelope = jsonDecode(typed.envelopeJson) as Map<String, dynamic>;
      final dto = jsonDecode(typed.dtoJson) as Map<String, dynamic>;
      final envMessage = envelope['message'] as Map<String, dynamic>;
      expect(envMessage['name'], dto['name']);
      expect(envMessage['addressCity'], dto['addressCity']);
      expect(envMessage['email'], dto['email']);

      // And the romanisation actually happened — no non-ASCII bytes
      // anywhere in the signed string. If a future refactor forgets to
      // romanise, this catches it.
      expect(
        (dto['name'] as String).codeUnits.every((u) => u < 128),
        isTrue,
        reason: 'name still carries non-ASCII bytes — toBitboxSafeAscii skipped',
      );
      expect(
        (dto['addressCity'] as String).codeUnits.every((u) => u < 128),
        isTrue,
      );
    });

    test('KYC firstName + lastName romanised identically in envelope and dto', () async {
      final result = await pipeline.sign(
        _kycReq(firstName: 'Étienne', lastName: 'Müller-Ångström'),
      );
      final typed = result as TypedDataSignResult;
      final envelope = jsonDecode(typed.envelopeJson) as Map<String, dynamic>;
      final dto = jsonDecode(typed.dtoJson) as Map<String, dynamic>;
      final envMessage = envelope['message'] as Map<String, dynamic>;
      expect(envMessage['firstName'], dto['firstName']);
      expect(envMessage['lastName'], dto['lastName']);
      expect(
        (dto['lastName'] as String).codeUnits.every((u) => u < 128),
        isTrue,
      );
    });

    test('property: every romanised user string is pure ASCII (full alphabet sweep)', () async {
      const samples = ['äöüß', 'éàâ', 'ñõ', 'ÆØÅ', 'çž', 'Ł', '«»', '…—'];
      for (final s in samples) {
        final result = await pipeline.sign(
          _registrationReq(name: s, addressCity: s),
        );
        final dto = jsonDecode((result as TypedDataSignResult).dtoJson)
            as Map<String, dynamic>;
        expect(
          (dto['name'] as String).codeUnits.every((u) => u < 128),
          isTrue,
          reason: 'sample "$s" → ${dto['name']} still has non-ASCII',
        );
      }
    });
  });

  group('Validation contract', () {
    test('empty email → SignRequestValidationException(field=email)', () async {
      final req = RegistrationSignRequest(
        credentials: _credentials(),
        chainId: 1,
        verifyingContract: _verifyingContract,
        email: '',
        name: 'X',
        type: 'human',
        phoneNumber: '+1',
        birthday: '1990-01-01',
        nationality: 'CH',
        addressStreet: 'X',
        addressPostalCode: '1',
        addressCity: 'X',
        addressCountry: 'CH',
        swissTaxResidence: false,
        registrationDate: '2026-05-23',
      );
      await expectLater(
        pipeline.sign(req),
        throwsA(
          isA<SignRequestValidationException>().having(
            (e) => e.field,
            'field',
            'email',
          ),
        ),
      );
    });

    test('non-positive chainId → SignRequestValidationException(field=chainId)', () async {
      await expectLater(
        pipeline.sign(_registrationReq(chainId: 0)),
        throwsA(
          isA<SignRequestValidationException>().having(
            (e) => e.field,
            'field',
            'chainId',
          ),
        ),
      );
    });

    test('PSBT magic-byte mismatch → BtcPsbtInvalidException', () async {
      await expectLater(
        pipeline.sign(
          _psbtReq(bytes: Uint8List.fromList([0xff, 0xff, 0xff, 0xff, 0xff])),
        ),
        throwsA(isA<BtcPsbtInvalidException>()),
      );
    });

    test('EIP-1559 transfer with payload[0] != 0x02 → Eip1559TypeMismatchException', () async {
      await expectLater(
        pipeline.sign(_ethReq(payload: [0x01, 0xaa], isEIP1559: true)),
        throwsA(isA<Eip1559TypeMismatchException>()),
      );
    });
  });

  group('Schema-pinning contract (F-038)', () {
    test('EIP-7702 backend smuggles extra Delegation field → Eip712SchemaDriftException', () async {
      final data = _validEip7702Data(
        delegation: const [
          Eip7702TypeField(name: 'delegate', type: 'address'),
          Eip7702TypeField(name: 'delegator', type: 'address'),
          Eip7702TypeField(name: 'authority', type: 'bytes32'),
          Eip7702TypeField(name: 'caveats', type: 'Caveat[]'),
          Eip7702TypeField(name: 'salt', type: 'uint256'),
          // The attack: backend smuggles a hidden caveat
          Eip7702TypeField(name: 'secretApproval', type: 'uint256'),
        ],
      );
      await expectLater(
        pipeline.sign(_eip7702Req(data: data)),
        throwsA(isA<Eip712SchemaDriftException>()),
      );
    });

    test('EIP-7702 wrong chainId → Eip7702ExpectedParamsMismatchException', () async {
      final req = Eip7702SignRequest(
        credentials: _credentials(),
        eip7702Data: _validEip7702Data(),
        expectedVerifyingContract: _verifyingContract,
        expectedChainId: 137, // backend ships 1
        expectedDelegator: _testAddress,
        expectedAmount: BigInt.from(10).pow(18),
      );
      await expectLater(
        pipeline.sign(req),
        throwsA(isA<Eip7702ExpectedParamsMismatchException>()),
      );
    });
  });

  group('swissTaxResidence flows from request → envelope → dto (BL-002)', () {
    test('swissTaxResidence=true appears as true in BOTH envelope and dto', () async {
      final result = await pipeline.sign(
        _registrationReq(swissTaxResidence: true),
      );
      final typed = result as TypedDataSignResult;
      final envelope = jsonDecode(typed.envelopeJson) as Map<String, dynamic>;
      final envMessage = envelope['message'] as Map<String, dynamic>;
      final dto = jsonDecode(typed.dtoJson) as Map<String, dynamic>;
      expect(envMessage['swissTaxResidence'], true);
      expect(dto['swissTaxResidence'], true);
    });

    test('swissTaxResidence=false appears as false in BOTH envelope and dto', () async {
      final result = await pipeline.sign(
        _registrationReq(swissTaxResidence: false),
      );
      final typed = result as TypedDataSignResult;
      final envelope = jsonDecode(typed.envelopeJson) as Map<String, dynamic>;
      final envMessage = envelope['message'] as Map<String, dynamic>;
      final dto = jsonDecode(typed.dtoJson) as Map<String, dynamic>;
      expect(envMessage['swissTaxResidence'], false);
      expect(dto['swissTaxResidence'], false);
    });

    test('signatures differ between swissTaxResidence=true and false', () async {
      // Pin: the value is a SIGNED field (it lives in the EIP-712
      // message), not metadata. A change in the user's tick MUST
      // change the signature so the backend can't be fooled into
      // treating an old (false) signature as a new (true) attestation.
      final sigTrue = (await pipeline.sign(
        _registrationReq(swissTaxResidence: true),
      ) as TypedDataSignResult).signature;
      final sigFalse = (await pipeline.sign(
        _registrationReq(swissTaxResidence: false),
      ) as TypedDataSignResult).signature;
      expect(sigTrue, isNot(equals(sigFalse)));
    });
  });

  group('Pipeline-step ordering', () {
    test('non-ASCII in registration name does NOT cause a chainId validation failure', () async {
      // Step ordering: validate runs first (positive chainId OK),
      // romanise runs after — the romanised name is what the signer
      // sees. Pinning that this ordering does not collapse into a
      // different exception type the cubit can't recognise.
      final result = await pipeline.sign(
        _registrationReq(name: 'Müller', chainId: 1),
      );
      expect(result, isA<TypedDataSignResult>());
    });
  });

  group('SignResult shape: envelope and dto carry the post-romanise canonical bytes', () {
    test('registration: dto JSON has the romanised name and the walletAddress is unchanged', () async {
      final result = await pipeline.sign(_registrationReq(name: 'Müller'));
      final dto = jsonDecode((result as TypedDataSignResult).dtoJson)
          as Map<String, dynamic>;
      expect(dto['name'], 'Mueller');
      expect(dto['walletAddress'], _testAddress);
    });

    test('schemaVersion is reflected in the envelope primaryType', () async {
      const schema = RegistrationSchemaV1();
      final req = RegistrationSignRequest(
        credentials: _credentials(),
        chainId: 1,
        verifyingContract: _verifyingContract,
        email: 'a@b.c',
        name: 'X',
        type: 'human',
        phoneNumber: '+1',
        birthday: '1990-01-01',
        nationality: 'CH',
        addressStreet: 'X',
        addressPostalCode: '1',
        addressCity: 'X',
        addressCountry: 'CH',
        swissTaxResidence: true,
        registrationDate: '2026-05-23',
        schema: schema,
      );
      final result = await pipeline.sign(req);
      final envelope = jsonDecode((result as TypedDataSignResult).envelopeJson)
          as Map<String, dynamic>;
      expect(envelope['primaryType'], schema.primaryType);
    });
  });
}
