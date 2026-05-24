// Tier-0 property tests for the chainId-in-domain invariant (F-041).
//
// What this pins (Initiative II / ADR 0002 step 8):
//
//  * Same registration payload signed on chainId=1 versus chainId=5
//    produces DIFFERENT signatures — cross-chain replay is now
//    structurally impossible for V1-domain signs.
//  * V0-legacy schema (no chainId in domain) still produces the SAME
//    signature for both chainIds — this is the backend-rollout
//    fallback. Tests pin the boundary: anyone migrating a callsite
//    from V0 → V1 sees the cross-chain replay protection turn on.
//  * The schema constant the signer uses determines the domain shape;
//    a refactor that defaults to V0 silently loses F-041 protection
//    and the boundary test fires.
//
// Property:
//
//   For every (schemaV1, payload, chainId_a, chainId_b) with
//   chainId_a != chainId_b → signature_a != signature_b.

import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/wallet/eip712_signer.dart';
import 'package:realunit_wallet/packages/wallet/schemas/registration_schema.dart';
import 'package:web3dart/web3dart.dart';

const _privateKeyHex = 'fb1ace12f9801e85f3db1b3935dd47d9f064f98152466f47c701b5e12680e612';
const _verifyingContract = '0x000000000000000000000000000000000000beef';

Future<String> _sign(
  Eip712Signer signer,
  int chainId, {
  required dynamic schema,
}) {
  return signer.signRegistrationEnvelope(
    credentials: EthPrivateKey.fromHex(_privateKeyHex),
    chainId: chainId,
    email: 'cross-chain@dfx.swiss',
    name: 'Cross Chain User',
    type: 'human',
    phoneNumber: '+41790000000',
    birthday: '1990-01-01',
    nationality: 'CH',
    addressStreet: 'Teststrasse 1',
    addressPostalCode: '8000',
    addressCity: 'Zurich',
    addressCountry: 'CH',
    swissTaxResidence: true,
    registrationDate: '2026-05-23',
    verifyingContract: _verifyingContract,
    schema: schema,
  );
}

void main() {
  const signer = Eip712Signer();

  group('F-041: chainId in registration domain (V1)', () {
    test(
      'same payload on chainId=1 vs chainId=5 produces DIFFERENT signatures',
      () async {
        const schema = RegistrationSchemaV1();
        final sigEth = await _sign(signer, 1, schema: schema);
        final sigGoerli = await _sign(signer, 5, schema: schema);
        expect(sigEth, isNotEmpty);
        expect(sigGoerli, isNotEmpty);
        expect(
          sigEth,
          isNot(equals(sigGoerli)),
          reason:
              'V1 domain includes chainId — a sig on chain A must not '
              'replay on chain B; F-041 would otherwise leave registration '
              'signatures cross-chain replayable.',
        );
      },
    );

    test('property: every pair of distinct chainIds yields distinct signatures', () async {
      const schema = RegistrationSchemaV1();
      const chains = [1, 5, 10, 56, 137, 8453, 42161];
      final signatures = <int, String>{};
      for (final c in chains) {
        signatures[c] = await _sign(signer, c, schema: schema);
      }
      // For every unordered pair (a, b) with a < b, signatures must
      // differ. This is the cross-chain replay safety invariant pinned
      // explicitly across a meaningful spread of mainnets / L2s / testnets.
      for (var i = 0; i < chains.length; i++) {
        for (var j = i + 1; j < chains.length; j++) {
          expect(
            signatures[chains[i]],
            isNot(equals(signatures[chains[j]])),
            reason:
                'chainId ${chains[i]} signature collides with ${chains[j]}; '
                'F-041 cross-chain replay protection broken.',
          );
        }
      }
    });

    test('idempotence: same payload on same chainId is byte-stable', () async {
      const schema = RegistrationSchemaV1();
      final sigA = await _sign(signer, 1, schema: schema);
      final sigB = await _sign(signer, 1, schema: schema);
      expect(
        sigA,
        sigB,
        reason:
            'eth_sig_util V4 is deterministic; a refactor that introduces '
            'non-determinism (e.g. a random salt) would break replay-safety '
            'guarantees and break this pin.',
      );
    });
  });

  group('V0-legacy boundary (no chainId in domain)', () {
    test(
      'V0-legacy schema: same payload on chainId=1 vs chainId=5 still produces SAME signature',
      () async {
        // The V0 domain is `name + version` only — the chainId is not
        // part of the signed hash. This is the legacy behaviour the
        // production backend currently still expects (backend rollout
        // window pinned in ADR 0002 §Failure modes). New callers go
        // through the SignPipeline with V1; the boundary test exists so
        // a refactor that silently defaults to V0 cannot escape audit.
        const schema = RegistrationSchemaV0();
        final sigEth = await _sign(signer, 1, schema: schema);
        final sigGoerli = await _sign(signer, 5, schema: schema);
        expect(
          sigEth,
          equals(sigGoerli),
          reason:
              'V0-legacy domain does not include chainId — cross-chain '
              'replay is structurally possible; the V1 schema closes this.',
        );
      },
    );
  });
}
