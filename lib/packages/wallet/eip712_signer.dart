// EIP-712 / EIP-7702 signer for the Dart side of the wallet.
//
// Initiative II refactor (ADR 0002):
//
//  * was: a `class Eip712Signer { static Future<String> signRegistration(...) }`
//    helper called directly from six different code paths.
//  * is now: a DI-injected service that the [SignPipeline] holds. Existing
//    `static` entrypoints are preserved as thin wrappers around a default
//    instance so the in-tree consumers
//    (`RealUnitRegistrationService`, `RealUnitSellPaymentInfoService`) can
//    migrate to the pipeline incrementally — see commit log for the planned
//    migration order.
//
// New surface (instance methods on a `const`-constructible class):
//
//   const Eip712Signer()
//
//   Future<String> signRegistrationEnvelope({...}) — instance method
//   building the `RealUnitUser` typed-data envelope. Domain includes
//   `chainId` (F-041 fix) and `verifyingContract` when the supplied
//   [schema] expects them; otherwise (V0 schema) falls back to the legacy
//   `name + version` shape for the backend-rollout window.
//
//   Future<String> signDelegationEnvelope({
//     required CredentialsWithKnownAddress credentials,
//     required Eip7702Data eip7702Data,
//     required String expectedVerifyingContract,
//     required int expectedChainId,
//     required String expectedDelegator,
//     required BigInt expectedAmount,
//     Eip7702DelegationSchema schema,
//   }) — schema-pinning lives inside the signer (F-039 closure). A future
//   caller cannot forget the validation step.
//
//   Future<String> signKycEnvelope({...}) — pinned via [KycSignSchema];
//   today this is exercised by the pipeline tests, production wiring lands
//   when NEW-19 closes.
//
//   Future<String> signTypedDataEnvelope({...}) — low-level entrypoint
//   used by [SignPipeline] when it constructs its own envelope. Routes
//   straight through to the platform signer.
//
// Backward-compat static methods:
//
//   `Eip712Signer.signRegistration(...)` and `.signDelegation(...)`
//   continue to work — they delegate to a default `const Eip712Signer()`.
//   Both legacy callsites remain working while the pipeline migration
//   rolls out. Existing tier-0 test
//   `test/packages/wallet/eip712_signer_test.dart` exercises the legacy
//   path; the new pipeline tests exercise the DI surface.

import 'dart:convert';

import 'package:eth_sig_util_plus/eth_sig_util_plus.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_credentials.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/eip7702/eip7702_data_dto.dart';
import 'package:realunit_wallet/packages/wallet/error_mapper.dart';
import 'package:realunit_wallet/packages/wallet/exceptions/signing_cancelled_exception.dart';
import 'package:realunit_wallet/packages/wallet/schemas/eip712_schema.dart';
import 'package:realunit_wallet/packages/wallet/schemas/eip7702_delegation_schema.dart';
import 'package:realunit_wallet/packages/wallet/schemas/kyc_sign_schema.dart';
import 'package:realunit_wallet/packages/wallet/schemas/registration_schema.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class Eip712Signer {
  /// Default constructor uses production wiring (real BitBox plugin /
  /// real `eth_sig_util_plus`). Const so callers can hold a stable
  /// default instance via `const Eip712Signer()`.
  const Eip712Signer();

  // ------------------------------------------------------------------------
  // Instance methods (the DI surface)
  // ------------------------------------------------------------------------

  /// Builds the `RealUnitUser` EIP-712 envelope and signs it. The domain
  /// includes `chainId` (F-041 fix) and `verifyingContract` when the
  /// supplied [schema] expects them; otherwise (V0 schema) falls back to
  /// the legacy `name + version` shape.
  Future<String> signRegistrationEnvelope({
    required CredentialsWithKnownAddress credentials,
    required int chainId,
    required String email,
    required String name,
    required String type,
    required String phoneNumber,
    required String birthday,
    required String nationality,
    required String addressStreet,
    required String addressPostalCode,
    required String addressCity,
    required String addressCountry,
    required bool swissTaxResidence,
    required String registrationDate,
    String? verifyingContract,
    Eip712Schema schema = const RegistrationSchemaV0(),
  }) {
    final domain = <String, dynamic>{
      'name': 'RealUnitUser',
      'version': '1',
      if (schema.types['EIP712Domain']!.any((f) => f.name == 'chainId'))
        'chainId': chainId,
      if (schema.types['EIP712Domain']!.any((f) => f.name == 'verifyingContract') &&
          verifyingContract != null)
        'verifyingContract': verifyingContract,
    };
    final Map<String, dynamic> typedDataMap = {
      'types': schema.typesAsJson(),
      'primaryType': schema.primaryType,
      'domain': domain,
      'message': {
        'email': email,
        'name': name,
        'type': type,
        'phoneNumber': phoneNumber,
        'birthday': birthday,
        'nationality': nationality,
        'addressStreet': addressStreet,
        'addressPostalCode': addressPostalCode,
        'addressCity': addressCity,
        'addressCountry': addressCountry,
        'swissTaxResidence': swissTaxResidence,
        'registrationDate': registrationDate,
        'walletAddress': credentials.address.hexEip55,
      },
    };

    return signTypedDataEnvelope(
      credentials: credentials,
      chainId: chainId,
      jsonEnvelope: jsonEncode(typedDataMap),
    );
  }

  /// EIP-7702 delegation sign with explicit pinned-parameter validation
  /// and schema-pinning. Closes F-038 / F-039 — a backend adding
  /// `{name: "secretApproval", type: "uint256"}` is refused before any
  /// byte reaches the BitBox plugin.
  ///
  /// The expected pinned parameters are validated INSIDE the signer
  /// rather than at the caller; that way a future caller cannot forget
  /// the validation step.
  Future<String> signDelegationEnvelope({
    required CredentialsWithKnownAddress credentials,
    required Eip7702Data eip7702Data,
    required String expectedVerifyingContract,
    required int expectedChainId,
    required String expectedDelegator,
    required BigInt expectedAmount,
    Eip7702DelegationSchema schema = const Eip7702DelegationSchema(),
  }) async {
    // Pinned-parameter validation FIRST — refuse to construct the
    // envelope if the backend has shifted any of the trusted parameters.
    if (eip7702Data.domain.verifyingContract.toLowerCase() !=
        expectedVerifyingContract.toLowerCase()) {
      throw Eip7702ExpectedParamsMismatchException(
        parameter: 'verifyingContract',
        expected: expectedVerifyingContract,
        actual: eip7702Data.domain.verifyingContract,
      );
    }
    if (eip7702Data.domain.chainId != expectedChainId) {
      throw Eip7702ExpectedParamsMismatchException(
        parameter: 'chainId',
        expected: '$expectedChainId',
        actual: '${eip7702Data.domain.chainId}',
      );
    }
    if (eip7702Data.message.delegator.toLowerCase() !=
        expectedDelegator.toLowerCase()) {
      throw Eip7702ExpectedParamsMismatchException(
        parameter: 'delegator',
        expected: expectedDelegator,
        actual: eip7702Data.message.delegator,
      );
    }
    final actualWei = BigInt.tryParse(eip7702Data.amountWei);
    if (actualWei == null || actualWei != expectedAmount) {
      throw Eip7702ExpectedParamsMismatchException(
        parameter: 'amountWei',
        expected: '$expectedAmount',
        actual: eip7702Data.amountWei,
      );
    }

    // Schema-pinning — byte-equal compare backend types against the
    // client-pinned [schema] constant.
    final backendTypes = <String, dynamic>{
      'EIP712Domain': const [
        {'name': 'name', 'type': 'string'},
        {'name': 'version', 'type': 'string'},
        {'name': 'chainId', 'type': 'uint256'},
        {'name': 'verifyingContract', 'type': 'address'},
      ],
      'Delegation': [
        for (final f in eip7702Data.types.delegation)
          {'name': f.name, 'type': f.type},
      ],
      'Caveat': [
        for (final f in eip7702Data.types.caveat)
          {'name': f.name, 'type': f.type},
      ],
    };
    schema.validate(backendTypes);

    final Map<String, dynamic> typedDataMap = {
      'types': schema.typesAsJson(),
      'primaryType': schema.primaryType,
      'domain': {
        'name': eip7702Data.domain.name,
        'version': eip7702Data.domain.version,
        'chainId': eip7702Data.domain.chainId,
        'verifyingContract': eip7702Data.domain.verifyingContract,
      },
      'message': {
        'delegate': eip7702Data.message.delegate,
        'delegator': eip7702Data.message.delegator,
        'authority': eip7702Data.message.authority,
        'caveats': eip7702Data.message.caveats,
        'salt': eip7702Data.message.salt,
      },
    };

    return signTypedDataEnvelope(
      credentials: credentials,
      chainId: eip7702Data.domain.chainId,
      jsonEnvelope: jsonEncode(typedDataMap),
    );
  }

  /// KYC standalone sign (future NEW-19 path). Exercised by the
  /// pipeline tests today; production callsite lands when NEW-19 PII
  /// migration ships.
  Future<String> signKycEnvelope({
    required CredentialsWithKnownAddress credentials,
    required int chainId,
    required String verifyingContract,
    required String accountType,
    required String firstName,
    required String lastName,
    required String phone,
    required String addressStreet,
    required String addressHouseNumber,
    required String addressZip,
    required String addressCity,
    required int addressCountry,
    required String registrationDate,
    Eip712Schema schema = const KycSignSchema(),
  }) {
    final Map<String, dynamic> typedDataMap = {
      'types': schema.typesAsJson(),
      'primaryType': schema.primaryType,
      'domain': {
        'name': 'RealUnitKyc',
        'version': '1',
        'chainId': chainId,
        'verifyingContract': verifyingContract,
      },
      'message': {
        'accountType': accountType,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'addressStreet': addressStreet,
        'addressHouseNumber': addressHouseNumber,
        'addressZip': addressZip,
        'addressCity': addressCity,
        'addressCountry': addressCountry,
        'walletAddress': credentials.address.hexEip55,
        'registrationDate': registrationDate,
      },
    };
    return signTypedDataEnvelope(
      credentials: credentials,
      chainId: chainId,
      jsonEnvelope: jsonEncode(typedDataMap),
    );
  }

  /// Low-level entrypoint — signs an arbitrary JSON typed-data envelope
  /// using the supplied [credentials]. Exposed so [SignPipeline] can
  /// build its own envelopes via the schema constants and submit them
  /// through a single (testable) seam.
  Future<String> signTypedDataEnvelope({
    required CredentialsWithKnownAddress credentials,
    required int chainId,
    required String jsonEnvelope,
  }) async {
    final signature = await switch (credentials) {
      BitboxCredentials() => credentials.signTypedDataV4(chainId, jsonEnvelope),
      EthPrivateKey() => Future.value(
        EthSigUtil.signTypedData(
          privateKey: bytesToHex(credentials.privateKey, include0x: true),
          jsonData: jsonEnvelope,
          version: TypedDataVersion.V4,
        ),
      ),
      _ => throw UnsupportedError('Unsupported credentials type: ${credentials.runtimeType}'),
    };
    // The BitBox swift wrapper returns empty bytes ('0x') when the user
    // cancels on the device or the BLE link drops mid-sign; without this
    // guard the empty sig would be sent to the backend and the abort would
    // be misread as a successful sign.
    if (signature.isEmpty || signature == '0x') {
      throw const SigningCancelledException();
    }
    return signature;
  }

  // ------------------------------------------------------------------------
  // Backward-compat static wrappers
  //
  // Call sites in `RealUnitRegistrationService` and
  // `RealUnitSellPaymentInfoService` still use the static entry points;
  // migrating those services to the [SignPipeline] is tracked separately.
  // The legacy `signRegistration` static keeps the V0 (no chainId in
  // domain) signature to remain bit-identical with what the production
  // backend currently expects. Once the backend coordination for V1
  // lands, callsites switch to the pipeline and these wrappers are
  // removed.
  // ------------------------------------------------------------------------

  static Future<String> signRegistration({
    required CredentialsWithKnownAddress credentials,
    required int chainId,
    required String email,
    required String name,
    required String type,
    required String phoneNumber,
    required String birthday,
    required String nationality,
    required String addressStreet,
    required String addressPostalCode,
    required String addressCity,
    required String addressCountry,
    required bool swissTaxResidence,
    required String registrationDate,
  }) {
    return const Eip712Signer().signRegistrationEnvelope(
      credentials: credentials,
      chainId: chainId,
      email: email,
      name: name,
      type: type,
      phoneNumber: phoneNumber,
      birthday: birthday,
      nationality: nationality,
      addressStreet: addressStreet,
      addressPostalCode: addressPostalCode,
      addressCity: addressCity,
      addressCountry: addressCountry,
      swissTaxResidence: swissTaxResidence,
      registrationDate: registrationDate,
      schema: const RegistrationSchemaV0(),
    );
  }

  static Future<String> signDelegation({
    required CredentialsWithKnownAddress credentials,
    required Eip7702Data eip7702Data,
  }) {
    // Legacy static delegation has no expected-params validation — the
    // caller side (real_unit_sell_payment_info_service.dart::
    // _validateEip7702Data) still does that until the migration to the
    // pipeline lands. The pipeline/instance method is the canonical
    // surface for new callers.
    final signer = const Eip712Signer();
    final Map<String, dynamic> typedDataMap = {
      'types': {
        'EIP712Domain': [
          {'name': 'name', 'type': 'string'},
          {'name': 'version', 'type': 'string'},
          {'name': 'chainId', 'type': 'uint256'},
          {'name': 'verifyingContract', 'type': 'address'},
        ],
        'Delegation': eip7702Data.types.delegation
            .map((field) => {'name': field.name, 'type': field.type})
            .toList(),
        'Caveat': eip7702Data.types.caveat
            .map((field) => {'name': field.name, 'type': field.type})
            .toList(),
      },
      'primaryType': 'Delegation',
      'domain': {
        'name': eip7702Data.domain.name,
        'version': eip7702Data.domain.version,
        'chainId': eip7702Data.domain.chainId,
        'verifyingContract': eip7702Data.domain.verifyingContract,
      },
      'message': {
        'delegate': eip7702Data.message.delegate,
        'delegator': eip7702Data.message.delegator,
        'authority': eip7702Data.message.authority,
        'caveats': eip7702Data.message.caveats,
        'salt': eip7702Data.message.salt,
      },
    };
    return signer.signTypedDataEnvelope(
      credentials: credentials,
      chainId: eip7702Data.domain.chainId,
      jsonEnvelope: jsonEncode(typedDataMap),
    );
  }
}
