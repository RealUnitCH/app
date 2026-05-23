// Client-pinned schema for the EIP-7702 sell-delegation sign.
//
// Today the backend ships `eip7702Data.types.delegation` + `caveat` and the
// signer (`Eip712Signer.signDelegation`) rebuilds the typed-data map
// VERBATIM from those arrays. F-038 worst-case scenario: a malicious or
// MITM-ed backend adds `{name: "secretApproval", type: "uint256"}` to
// `delegation`; the user sees the visible amount in the validate-UI, taps
// sign, and the BitBox signs the smuggled field too.
//
// This schema is the trust root: the pipeline compares the backend-supplied
// `types` against this constant **byte-equal** and refuses to sign the
// envelope if there is any deviation. The validation logic uses the same
// `Eip712Schema.validate` comparator as the registration schema — see
// `eip712_schema.dart` for the per-cell semantics.
//
// `Delegation` type signature (MetaMask Delegation Framework v1.3.0):
//
//     Delegation(address delegate,
//                address delegator,
//                bytes32 authority,
//                Caveat[] caveats,
//                uint256 salt)
//     Caveat(address enforcer,
//            bytes terms)
//
// Source: https://github.com/MetaMask/delegation-framework v1.3.0
// (also documented in the testkit: §4.10 — Sell-EIP-7702 pre-flight).

import 'package:realunit_wallet/packages/wallet/schemas/eip712_schema.dart';

class Eip7702DelegationSchema extends Eip712Schema {
  const Eip7702DelegationSchema();

  @override
  String get schemaVersion => 'eip7702-delegation/v1';

  @override
  String get primaryType => 'Delegation';

  @override
  Map<String, List<Eip712FieldSpec>> get types => const {
    'EIP712Domain': [
      Eip712FieldSpec('name', 'string'),
      Eip712FieldSpec('version', 'string'),
      Eip712FieldSpec('chainId', 'uint256'),
      Eip712FieldSpec('verifyingContract', 'address'),
    ],
    'Delegation': [
      Eip712FieldSpec('delegate', 'address'),
      Eip712FieldSpec('delegator', 'address'),
      Eip712FieldSpec('authority', 'bytes32'),
      Eip712FieldSpec('caveats', 'Caveat[]'),
      Eip712FieldSpec('salt', 'uint256'),
    ],
    'Caveat': [
      Eip712FieldSpec('enforcer', 'address'),
      Eip712FieldSpec('terms', 'bytes'),
    ],
  };
}
