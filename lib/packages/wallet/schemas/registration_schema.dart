// Client-pinned schema for the EIP-712 RealUnit registration sign.
//
// V1 mirrors the current backend payload exactly (see
// `lib/packages/wallet/eip712_signer.dart::signRegistration` before the
// Initiative II refactor):
//
//   primaryType: `RealUnitUser`
//   fields:      email, name, type, phoneNumber, birthday, nationality,
//                addressStreet, addressPostalCode, addressCity,
//                addressCountry, swissTaxResidence, registrationDate,
//                walletAddress
//
// Domain (`EIP712Domain`) carries `name`, `version`, `chainId` (F-041 fix),
// and `verifyingContract` so registration signatures are
// chain-and-issuer-scoped. Backend rollout for `chainId`/`verifyingContract`
// is tracked in the Initiative II journal — until both endpoints accept the
// new domain bytes, the pipeline can fall back to a `name+version` schema
// via a v0 (non-pinned) bypass. The default schema for new clients is V1.

import 'package:realunit_wallet/packages/wallet/schemas/eip712_schema.dart';

class RegistrationSchemaV1 extends Eip712Schema {
  const RegistrationSchemaV1();

  @override
  String get schemaVersion => 'registration/v1';

  @override
  String get primaryType => 'RealUnitUser';

  @override
  Map<String, List<Eip712FieldSpec>> get types => const {
    'EIP712Domain': [
      Eip712FieldSpec('name', 'string'),
      Eip712FieldSpec('version', 'string'),
      Eip712FieldSpec('chainId', 'uint256'),
      Eip712FieldSpec('verifyingContract', 'address'),
    ],
    'RealUnitUser': [
      Eip712FieldSpec('email', 'string'),
      Eip712FieldSpec('name', 'string'),
      Eip712FieldSpec('type', 'string'),
      Eip712FieldSpec('phoneNumber', 'string'),
      Eip712FieldSpec('birthday', 'string'),
      Eip712FieldSpec('nationality', 'string'),
      Eip712FieldSpec('addressStreet', 'string'),
      Eip712FieldSpec('addressPostalCode', 'string'),
      Eip712FieldSpec('addressCity', 'string'),
      Eip712FieldSpec('addressCountry', 'string'),
      Eip712FieldSpec('swissTaxResidence', 'bool'),
      Eip712FieldSpec('registrationDate', 'string'),
      Eip712FieldSpec('walletAddress', 'address'),
    ],
  };
}

/// Legacy `name + version` domain schema (no `chainId`, no
/// `verifyingContract`) — kept available for the backend-rollout window
/// where the production backend has not yet been upgraded to verify the
/// new domain. The pipeline picks this only when the SignRequest carries
/// an explicit `legacyDomain: true` flag.
class RegistrationSchemaV0 extends Eip712Schema {
  const RegistrationSchemaV0();

  @override
  String get schemaVersion => 'registration/v0-legacy';

  @override
  String get primaryType => 'RealUnitUser';

  @override
  Map<String, List<Eip712FieldSpec>> get types => const {
    'EIP712Domain': [
      Eip712FieldSpec('name', 'string'),
      Eip712FieldSpec('version', 'string'),
    ],
    'RealUnitUser': [
      Eip712FieldSpec('email', 'string'),
      Eip712FieldSpec('name', 'string'),
      Eip712FieldSpec('type', 'string'),
      Eip712FieldSpec('phoneNumber', 'string'),
      Eip712FieldSpec('birthday', 'string'),
      Eip712FieldSpec('nationality', 'string'),
      Eip712FieldSpec('addressStreet', 'string'),
      Eip712FieldSpec('addressPostalCode', 'string'),
      Eip712FieldSpec('addressCity', 'string'),
      Eip712FieldSpec('addressCountry', 'string'),
      Eip712FieldSpec('swissTaxResidence', 'bool'),
      Eip712FieldSpec('registrationDate', 'string'),
      Eip712FieldSpec('walletAddress', 'address'),
    ],
  };
}
