// Tier-0 tests for Eip712Signer.signDelegationEnvelope — EIP-7702
// schema pinning with explicit expected parameters.
//
// What this pins (Initiative II / ADR 0002 step 7):
//
//  * F-038 — backend-supplied `types.delegation` adding a hidden field
//    raises Eip712SchemaDriftException BEFORE any byte reaches the
//    underlying eth_sig_util signer.
//  * F-039 — verifyingContract / chainId / delegator / amount that
//    differ from the expected pinned values raise
//    Eip7702ExpectedParamsMismatchException with the parameter name
//    populated, so the cubit can log which field drifted.
//  * Happy path — a backend response that matches all four pinned
//    parameters AND the pinned schema produces a non-empty signature.
//
// The signer validates internally, refusing to delegate the validation
// to "the caller will check it" — encapsulation lives inside the trust
// boundary. Closes the failure-mode entry in ADR 0002 §Failure modes:
//   "Schema constant drift from backend ↘ caught by _pinSchema byte-equal".

import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/eip7702/eip7702_data_dto.dart';
import 'package:realunit_wallet/packages/wallet/eip712_signer.dart';
import 'package:realunit_wallet/packages/wallet/error_mapper.dart';
import 'package:web3dart/web3dart.dart';

const _privateKeyHex = 'fb1ace12f9801e85f3db1b3935dd47d9f064f98152466f47c701b5e12680e612';
// Derived address of the test private key — keep in sync with
// FakeBitboxCredentials._testPrivateKeyHex.
const _testAddress = '0x9F5713dEAcb8e9CaB6c2D3FaE1aFc2715F8D2D71';
const _verifyingContract = '0xdb9b1e94b5b69df7e401ddbede43491141047db3';
const _relayer = '0x0000000000000000000000000000000000000abc';

Eip7702Data _validResponse({
  int chainId = 1,
  String verifyingContract = _verifyingContract,
  String delegator = _testAddress,
  String amountWei = '1000000000000000000', // 1 ETH
  List<Eip7702TypeField>? delegation,
  List<Eip7702TypeField>? caveat,
}) {
  return Eip7702Data(
    relayerAddress: _relayer,
    delegationManagerAddress: _verifyingContract,
    delegatorAddress: delegator,
    userNonce: 0,
    domain: Eip7702Domain(
      name: 'DelegationManager',
      version: '1',
      chainId: chainId,
      verifyingContract: verifyingContract,
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
      caveat:
          caveat ??
          const [
            Eip7702TypeField(name: 'enforcer', type: 'address'),
            Eip7702TypeField(name: 'terms', type: 'bytes'),
          ],
    ),
    message: Eip7702Message(
      delegate: _relayer,
      delegator: delegator,
      authority:
          '0x0000000000000000000000000000000000000000000000000000000000000000',
      caveats: const [],
      salt: 0,
    ),
    tokenAddress: '0x0000000000000000000000000000000000000aaa',
    amountWei: amountWei,
    depositAddress: '0x0000000000000000000000000000000000000bbb',
  );
}

void main() {
  final credentials = EthPrivateKey.fromHex(_privateKeyHex);
  const signer = Eip712Signer();

  group('Eip712Signer.signDelegationEnvelope expected-params pinning (F-039)', () {
    test('happy path: pinned params match → returns non-empty signature', () async {
      final sig = await signer.signDelegationEnvelope(
        credentials: credentials,
        eip7702Data: _validResponse(),
        expectedVerifyingContract: _verifyingContract,
        expectedChainId: 1,
        expectedDelegator: _testAddress,
        expectedAmount: BigInt.from(10).pow(18),
      );
      expect(sig, isNotEmpty);
      expect(sig, startsWith('0x'));
    });

    test('verifyingContract drift → Eip7702ExpectedParamsMismatchException', () async {
      await expectLater(
        signer.signDelegationEnvelope(
          credentials: credentials,
          eip7702Data: _validResponse(),
          expectedVerifyingContract: '0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef',
          expectedChainId: 1,
          expectedDelegator: _testAddress,
          expectedAmount: BigInt.from(10).pow(18),
        ),
        throwsA(
          isA<Eip7702ExpectedParamsMismatchException>().having(
            (e) => e.parameter,
            'parameter',
            'verifyingContract',
          ),
        ),
      );
    });

    test('chainId drift → Eip7702ExpectedParamsMismatchException carrying chainId', () async {
      await expectLater(
        signer.signDelegationEnvelope(
          credentials: credentials,
          eip7702Data: _validResponse(chainId: 1),
          expectedVerifyingContract: _verifyingContract,
          expectedChainId: 5,
          expectedDelegator: _testAddress,
          expectedAmount: BigInt.from(10).pow(18),
        ),
        throwsA(
          isA<Eip7702ExpectedParamsMismatchException>()
              .having((e) => e.parameter, 'parameter', 'chainId')
              .having((e) => e.expected, 'expected', '5')
              .having((e) => e.actual, 'actual', '1'),
        ),
      );
    });

    test('delegator drift → Eip7702ExpectedParamsMismatchException', () async {
      await expectLater(
        signer.signDelegationEnvelope(
          credentials: credentials,
          eip7702Data: _validResponse(
            delegator: '0x0000000000000000000000000000000000001234',
          ),
          expectedVerifyingContract: _verifyingContract,
          expectedChainId: 1,
          expectedDelegator: _testAddress,
          expectedAmount: BigInt.from(10).pow(18),
        ),
        throwsA(
          isA<Eip7702ExpectedParamsMismatchException>().having(
            (e) => e.parameter,
            'parameter',
            'delegator',
          ),
        ),
      );
    });

    test('amount drift → Eip7702ExpectedParamsMismatchException', () async {
      await expectLater(
        signer.signDelegationEnvelope(
          credentials: credentials,
          eip7702Data: _validResponse(amountWei: '500000000000000000'),
          expectedVerifyingContract: _verifyingContract,
          expectedChainId: 1,
          expectedDelegator: _testAddress,
          expectedAmount: BigInt.from(10).pow(18),
        ),
        throwsA(
          isA<Eip7702ExpectedParamsMismatchException>().having(
            (e) => e.parameter,
            'parameter',
            'amountWei',
          ),
        ),
      );
    });

    test('case-insensitive verifyingContract compare (mixed case via EIP-55)', () async {
      // The pinned compare lowercases both sides — the signer does not
      // care whether the backend ships EIP-55 mixed-case or lowercase.
      // Use a valid EIP-55 spelling here so the downstream eth_sig_util
      // address encoder can still parse the bytes.
      const mixedCase = '0xdB9b1E94B5B69dF7e401dDBEdE43491141047Db3';
      final sig = await signer.signDelegationEnvelope(
        credentials: credentials,
        eip7702Data: _validResponse(verifyingContract: mixedCase),
        expectedVerifyingContract: _verifyingContract,
        expectedChainId: 1,
        expectedDelegator: _testAddress,
        expectedAmount: BigInt.from(10).pow(18),
      );
      expect(sig, isNotEmpty);
    });

    test('case-insensitive delegator compare (mixed case via EIP-55)', () async {
      // _testAddress is already mixed-case (EIP-55); compare against the
      // lowercased spelling — the signer must accept either side.
      final sig = await signer.signDelegationEnvelope(
        credentials: credentials,
        eip7702Data: _validResponse(delegator: _testAddress),
        expectedVerifyingContract: _verifyingContract,
        expectedChainId: 1,
        expectedDelegator: _testAddress.toLowerCase(),
        expectedAmount: BigInt.from(10).pow(18),
      );
      expect(sig, isNotEmpty);
    });
  });

  group('Eip712Signer.signDelegationEnvelope schema pinning (F-038)', () {
    test('backend adds a hidden field → Eip712SchemaDriftException', () async {
      // The attack scenario the ADR explicitly names: a malicious /
      // MITM-ed backend smuggles `{name: "secretApproval", type:
      // "uint256"}` into the Delegation field list. The signer MUST
      // refuse before any byte reaches the device.
      await expectLater(
        signer.signDelegationEnvelope(
          credentials: credentials,
          eip7702Data: _validResponse(
            delegation: const [
              Eip7702TypeField(name: 'delegate', type: 'address'),
              Eip7702TypeField(name: 'delegator', type: 'address'),
              Eip7702TypeField(name: 'authority', type: 'bytes32'),
              Eip7702TypeField(name: 'caveats', type: 'Caveat[]'),
              Eip7702TypeField(name: 'salt', type: 'uint256'),
              Eip7702TypeField(name: 'secretApproval', type: 'uint256'),
            ],
          ),
          expectedVerifyingContract: _verifyingContract,
          expectedChainId: 1,
          expectedDelegator: _testAddress,
          expectedAmount: BigInt.from(10).pow(18),
        ),
        throwsA(
          isA<Eip712SchemaDriftException>().having(
            (e) => e.schemaVersion,
            'schemaVersion',
            'eip7702-delegation/v1',
          ),
        ),
      );
    });

    test('backend drops `salt` → Eip712SchemaDriftException', () async {
      await expectLater(
        signer.signDelegationEnvelope(
          credentials: credentials,
          eip7702Data: _validResponse(
            delegation: const [
              Eip7702TypeField(name: 'delegate', type: 'address'),
              Eip7702TypeField(name: 'delegator', type: 'address'),
              Eip7702TypeField(name: 'authority', type: 'bytes32'),
              Eip7702TypeField(name: 'caveats', type: 'Caveat[]'),
            ],
          ),
          expectedVerifyingContract: _verifyingContract,
          expectedChainId: 1,
          expectedDelegator: _testAddress,
          expectedAmount: BigInt.from(10).pow(18),
        ),
        throwsA(isA<Eip712SchemaDriftException>()),
      );
    });

    test('backend swaps delegate ↔ delegator → Eip712SchemaDriftException', () async {
      await expectLater(
        signer.signDelegationEnvelope(
          credentials: credentials,
          eip7702Data: _validResponse(
            delegation: const [
              Eip7702TypeField(name: 'delegator', type: 'address'),
              Eip7702TypeField(name: 'delegate', type: 'address'),
              Eip7702TypeField(name: 'authority', type: 'bytes32'),
              Eip7702TypeField(name: 'caveats', type: 'Caveat[]'),
              Eip7702TypeField(name: 'salt', type: 'uint256'),
            ],
          ),
          expectedVerifyingContract: _verifyingContract,
          expectedChainId: 1,
          expectedDelegator: _testAddress,
          expectedAmount: BigInt.from(10).pow(18),
        ),
        throwsA(isA<Eip712SchemaDriftException>()),
      );
    });

    test('backend changes Caveat.terms from bytes to bytes32 → Eip712SchemaDriftException', () async {
      await expectLater(
        signer.signDelegationEnvelope(
          credentials: credentials,
          eip7702Data: _validResponse(
            caveat: const [
              Eip7702TypeField(name: 'enforcer', type: 'address'),
              Eip7702TypeField(name: 'terms', type: 'bytes32'),
            ],
          ),
          expectedVerifyingContract: _verifyingContract,
          expectedChainId: 1,
          expectedDelegator: _testAddress,
          expectedAmount: BigInt.from(10).pow(18),
        ),
        throwsA(isA<Eip712SchemaDriftException>()),
      );
    });
  });
}
