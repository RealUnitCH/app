// Client-pinned schema for KYC-step typed-data signs.
//
// Today RealUnit does not run a separate `signKyc` call — KYC data is signed
// inside `signRegistration` (and intentionally also kept in the parallel
// `kycData` DTO sub-object with UTF-8 preserved for ID verification, see
// F-019). The `KycSignSchema` here is the structure the pipeline expects
// IF a future KYC-only sign step is added (the audit's NEW-19 PII-sig
// migration target). Pinning it now means the migration cannot ship without
// a matching schema entry and a backend-side rollout.
//
// Primary type `RealUnitKyc` with the personal-data envelope the API
// stores via `KycPersonalData` (lib/packages/service/dfx/models/registration
// /kyc/kyc_personal_data.dart). For the time being the schema's only
// production consumer is the test fixture proving the pipeline supports
// six entrypoints; the field set will be revisited when NEW-19 lands.

import 'package:realunit_wallet/packages/wallet/schemas/eip712_schema.dart';

class KycSignSchema extends Eip712Schema {
  const KycSignSchema();

  @override
  String get schemaVersion => 'kyc/v1';

  @override
  String get primaryType => 'RealUnitKyc';

  @override
  Map<String, List<Eip712FieldSpec>> get types => const {
    'EIP712Domain': [
      Eip712FieldSpec('name', 'string'),
      Eip712FieldSpec('version', 'string'),
      Eip712FieldSpec('chainId', 'uint256'),
      Eip712FieldSpec('verifyingContract', 'address'),
    ],
    'RealUnitKyc': [
      Eip712FieldSpec('accountType', 'string'),
      Eip712FieldSpec('firstName', 'string'),
      Eip712FieldSpec('lastName', 'string'),
      Eip712FieldSpec('phone', 'string'),
      Eip712FieldSpec('addressStreet', 'string'),
      Eip712FieldSpec('addressHouseNumber', 'string'),
      Eip712FieldSpec('addressZip', 'string'),
      Eip712FieldSpec('addressCity', 'string'),
      Eip712FieldSpec('addressCountry', 'uint256'),
      Eip712FieldSpec('walletAddress', 'address'),
      Eip712FieldSpec('registrationDate', 'string'),
    ],
  };
}
