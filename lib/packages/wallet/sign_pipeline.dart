// SignPipeline — the single Dart-side entry between a [SignRequest] and
// the BitBox plugin.
//
// Architectural goal (ADR 0002): every sign flow in the app — registration,
// re-register-wallet (KYC merge), sell EIP-7702 delegation, generic ETH
// transfer, future BTC PSBT, future KYC-only sign — funnels through the
// same five steps:
//
//   _validate → _romanise → _pinSchema → _submitToBitbox → _mapResult
//
// What each step guarantees:
//
//  * _validate     pins the [SignRequest] shape (non-empty required
//                  fields, plausible chainId, etc.). Closes the
//                  swissTaxResidence/email/registrationDate "looks
//                  empty" leak class (F-002 / F-019).
//  * _romanise     runs [toBitboxSafeAscii] on EVERY user string of
//                  BOTH the envelope and the DTO so the signed bytes
//                  match the backend-stored bytes (F-019 closure).
//                  Returns a "romanised" copy of the request that is
//                  the single source of truth for everything below.
//  * _pinSchema    byte-equal compares any backend-supplied EIP-712
//                  `types` map against the client-pinned schema
//                  constant. Extra/missing/reordered/wrong-type field
//                  raises [Eip712SchemaDriftException] **before** any
//                  byte reaches the BitBox (F-038 closure).
//  * _submitToBitbox  the sole callsite that hits the underlying
//                  [Eip712Signer] / [BitboxCredentials] plugin.
//  * _mapResult    catches anything the plugin throws and routes via
//                  [ErrorMapper] so the cubit always sees a typed
//                  [SignException].
//
// Six entrypoints (sealed [SignRequest] hierarchy):
//
//   RegistrationSignRequest, KycSignRequest, SellSignRequest,
//   Eip7702SignRequest, BtcPsbtSignRequest, EthTransferSignRequest
//
// Each carries the parameters specific to that flow plus an explicit
// schema reference so the pinning step has a single constant to compare
// against. Property test in
// `test/packages/wallet/sign_pipeline_test.dart` asserts
// `pipeline(s).envelope == pipeline(s).dto` byte-equal post-romanise for
// every entrypoint.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/eip7702/eip7702_data_dto.dart';
import 'package:realunit_wallet/packages/utils/ascii_transliterate.dart';
import 'package:realunit_wallet/packages/wallet/eip712_signer.dart';
import 'package:realunit_wallet/packages/wallet/error_mapper.dart';
import 'package:realunit_wallet/packages/wallet/exceptions/signing_cancelled_exception.dart';
import 'package:realunit_wallet/packages/wallet/schemas/btc_psbt_schema.dart';
import 'package:realunit_wallet/packages/wallet/schemas/eip712_schema.dart';
import 'package:realunit_wallet/packages/wallet/schemas/eip7702_delegation_schema.dart';
import 'package:realunit_wallet/packages/wallet/schemas/kyc_sign_schema.dart';
import 'package:realunit_wallet/packages/wallet/schemas/registration_schema.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

// ---------------------------------------------------------------------------
// SignRequest hierarchy
// ---------------------------------------------------------------------------

/// Tag-only superclass for the six pipeline entrypoints.
///
/// Sealed-style: every concrete subclass lives in this file so the
/// pipeline's `switch (request)` statement is exhaustive at compile
/// time. A new entrypoint adds a new subclass here and a new switch
/// branch in [SignPipeline.sign]; the missing branch turns the analyzer
/// red.
sealed class SignRequest {
  const SignRequest();

  /// Credentials used to sign. For Tier-0 tests this is a
  /// [FakeBitboxCredentials] or a raw [EthPrivateKey]; in production it is
  /// the wallet's [primaryAddress].
  CredentialsWithKnownAddress get credentials;
}

/// Registration / re-register-wallet sign.
///
/// Carries the entire ASCII-safe field set the EIP-712 envelope
/// requires. The pipeline does NOT compute fields from raw form input —
/// the caller is responsible for supplying romanisable strings; the
/// pipeline guarantees the romanised view is used for BOTH the signed
/// envelope and the DTO.
class RegistrationSignRequest extends SignRequest {
  @override
  final CredentialsWithKnownAddress credentials;
  final int chainId;
  final String verifyingContract;
  final String email;
  final String name;
  final String type;
  final String phoneNumber;
  final String birthday;
  final String nationality;
  final String addressStreet;
  final String addressPostalCode;
  final String addressCity;
  final String addressCountry;
  final bool swissTaxResidence;

  /// Server-issued timestamp (`yyyy-MM-dd`). The client never signs
  /// `DateTime.now()` — F-042. Supplied by the backend in the
  /// registration request so a jail-broken device clock cannot post-date
  /// a sign.
  final String registrationDate;

  /// Schema to pin against. Defaults to V1 (`chainId` + `verifyingContract`
  /// in domain). Tests may inject a V0-legacy schema for the
  /// backend-rollout window.
  final Eip712Schema schema;

  const RegistrationSignRequest({
    required this.credentials,
    required this.chainId,
    required this.verifyingContract,
    required this.email,
    required this.name,
    required this.type,
    required this.phoneNumber,
    required this.birthday,
    required this.nationality,
    required this.addressStreet,
    required this.addressPostalCode,
    required this.addressCity,
    required this.addressCountry,
    required this.swissTaxResidence,
    required this.registrationDate,
    this.schema = const RegistrationSchemaV1(),
  });
}

/// Standalone KYC sign (future NEW-19 PII-sig migration). The schema
/// pinning is the same byte-equal compare; the wire format mirrors
/// [KycSignSchema].
class KycSignRequest extends SignRequest {
  @override
  final CredentialsWithKnownAddress credentials;
  final int chainId;
  final String verifyingContract;
  final String accountType;
  final String firstName;
  final String lastName;
  final String phone;
  final String addressStreet;
  final String addressHouseNumber;
  final String addressZip;
  final String addressCity;
  final int addressCountry;
  final String registrationDate;
  final Eip712Schema schema;

  const KycSignRequest({
    required this.credentials,
    required this.chainId,
    required this.verifyingContract,
    required this.accountType,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.addressStreet,
    required this.addressHouseNumber,
    required this.addressZip,
    required this.addressCity,
    required this.addressCountry,
    required this.registrationDate,
    this.schema = const KycSignSchema(),
  });
}

/// EIP-7702 sell-delegation sign. The pipeline rejects the request if
/// any of the expected pinned parameters differ from the backend
/// response (F-039) — schema pinning lives inside the signer not in the
/// caller.
class Eip7702SignRequest extends SignRequest {
  @override
  final CredentialsWithKnownAddress credentials;
  final Eip7702Data eip7702Data;

  /// Verifying contract the client expects in the EIP-712 domain
  /// (i.e. the DelegationManager). A mismatch raises
  /// [Eip7702ExpectedParamsMismatchException].
  final String expectedVerifyingContract;

  /// chainId the client expects in the EIP-712 domain.
  final int expectedChainId;

  /// Delegator the client expects in `message.delegator` (the user's
  /// wallet address, lowercased for the compare).
  final String expectedDelegator;

  /// Sell amount the client expects in `amountWei`, as a [BigInt] in
  /// wei units (decimals already applied by the caller).
  final BigInt expectedAmount;

  final Eip7702DelegationSchema schema;

  const Eip7702SignRequest({
    required this.credentials,
    required this.eip7702Data,
    required this.expectedVerifyingContract,
    required this.expectedChainId,
    required this.expectedDelegator,
    required this.expectedAmount,
    this.schema = const Eip7702DelegationSchema(),
  });
}

/// Sell sign — wraps an EIP-7702 sign for the production sell flow.
/// Distinct from [Eip7702SignRequest] only at the SignRequest type level
/// (so cubits can dispatch / log differently); pipeline behaviour is
/// identical. Kept separate per the ADR's "six entrypoints" contract.
class SellSignRequest extends Eip7702SignRequest {
  const SellSignRequest({
    required super.credentials,
    required super.eip7702Data,
    required super.expectedVerifyingContract,
    required super.expectedChainId,
    required super.expectedDelegator,
    required super.expectedAmount,
    super.schema = const Eip7702DelegationSchema(),
  });
}

/// BTC PSBT sign. Carries raw bytes; the pipeline runs
/// [BtcPsbtSchema.validatePsbt] as the pre-flight (magic bytes + length
/// sanity). The BitBox firmware then performs the full BIP-174 parse on
/// device.
class BtcPsbtSignRequest extends SignRequest {
  @override
  final CredentialsWithKnownAddress credentials;
  final Uint8List psbtBytes;
  final BtcPsbtSchema schema;

  const BtcPsbtSignRequest({
    required this.credentials,
    required this.psbtBytes,
    this.schema = const BtcPsbtSchema(),
  });
}

/// Generic raw-payload ETH transfer sign (legacy or EIP-1559). The
/// pipeline asserts the `payload[0] == 0x02` type byte when
/// [isEIP1559] is `true` (F-040) before reaching the signer.
class EthTransferSignRequest extends SignRequest {
  @override
  final CredentialsWithKnownAddress credentials;
  final Uint8List payload;
  final int chainId;
  final bool isEIP1559;

  const EthTransferSignRequest({
    required this.credentials,
    required this.payload,
    required this.chainId,
    this.isEIP1559 = false,
  });
}

// ---------------------------------------------------------------------------
// SignResult hierarchy
// ---------------------------------------------------------------------------

/// Tag-only superclass for the pipeline outputs. Cubits switch on the
/// variant to extract the bytes (`signature` for typed-data sign,
/// `signedTx` for transfer sign).
sealed class SignResult {
  const SignResult();
}

/// EIP-712 / EIP-7702 typed-data signature (hex-encoded with 0x
/// prefix). Used for registration, KYC, sell, EIP-7702 entrypoints.
class TypedDataSignResult extends SignResult {
  final String signature;

  /// Envelope JSON the signature was produced over. Stored so callers
  /// can persist it / compare against the DTO byte-equal in tests.
  final String envelopeJson;

  /// DTO JSON sent to the backend (post-romanise, post-schema-pin).
  final String dtoJson;

  const TypedDataSignResult({
    required this.signature,
    required this.envelopeJson,
    required this.dtoJson,
  });
}

/// Raw transaction signature ([MsgSignature]). Used for the ETH transfer
/// entrypoint.
class EthTransferSignResult extends SignResult {
  final MsgSignature signature;
  const EthTransferSignResult(this.signature);
}

/// PSBT placeholder — production implementation in Initiative III
/// scenarios; here we expose only the validated bytes so the rest of
/// the pipeline contract is exercised by tests today.
class BtcPsbtSignResult extends SignResult {
  final Uint8List signedPsbt;
  const BtcPsbtSignResult(this.signedPsbt);
}

// ---------------------------------------------------------------------------
// SignPipeline
// ---------------------------------------------------------------------------

/// Single Dart-side entry between a [SignRequest] and the BitBox
/// plugin. See file header for the architectural contract.
class SignPipeline {
  /// EIP-712 signer used for typed-data flows. Injected so tests can
  /// substitute a fake; production wires the real `Eip712Signer`.
  final Eip712Signer eip712Signer;

  /// Error mapper used for the `catch` boundary. Configurable so tests
  /// can substitute a mapper that records calls.
  final ErrorMapper errorMapper;

  const SignPipeline({
    this.eip712Signer = const Eip712Signer(),
    this.errorMapper = const ErrorMapper(),
  });

  /// Run a [SignRequest] through the pipeline. Returns the variant of
  /// [SignResult] matching the request entrypoint. Throws a typed
  /// [SignException] subclass on any failure — never an opaque
  /// `Exception` / `Error` / `String`.
  Future<SignResult> sign(SignRequest request) async {
    try {
      _validate(request);
      final romanised = _romanise(request);
      _pinSchema(romanised);
      return await _submitToBitbox(romanised);
    } on SignException {
      // Already typed — let it propagate without re-wrapping (would
      // lose the typed branch and force consumers to unwrap).
      rethrow;
    } on SigningCancelledException catch (e) {
      throw errorMapper.mapCause(e);
    } on BitboxNotConnectedException catch (e) {
      throw errorMapper.mapCause(e);
    } catch (e) {
      // Any other throwable (e.g. a plugin returning a raw String, a
      // FormatException from a malformed signature) is funnelled
      // through the mapper so the cubit ALWAYS sees a typed
      // [SignException] — closes the F-016 / F-020 / F-021 cluster
      // (cubits doing `catch (e) { e.toString() }`).
      throw errorMapper.mapCause(e);
    }
  }

  // -------------------------------------------------------------------------
  // _validate — field-presence + plausible-type contracts
  // -------------------------------------------------------------------------

  void _validate(SignRequest request) {
    switch (request) {
      case RegistrationSignRequest():
        _requireNonEmpty('email', request.email);
        _requireNonEmpty('name', request.name);
        _requireNonEmpty('type', request.type);
        _requireNonEmpty('phoneNumber', request.phoneNumber);
        _requireNonEmpty('birthday', request.birthday);
        _requireNonEmpty('nationality', request.nationality);
        _requireNonEmpty('addressStreet', request.addressStreet);
        _requireNonEmpty('addressPostalCode', request.addressPostalCode);
        _requireNonEmpty('addressCity', request.addressCity);
        _requireNonEmpty('addressCountry', request.addressCountry);
        _requireNonEmpty('registrationDate', request.registrationDate);
        _requireNonEmpty('verifyingContract', request.verifyingContract);
        _requirePositive('chainId', request.chainId);
      case KycSignRequest():
        _requireNonEmpty('accountType', request.accountType);
        _requireNonEmpty('firstName', request.firstName);
        _requireNonEmpty('lastName', request.lastName);
        _requireNonEmpty('phone', request.phone);
        _requireNonEmpty('addressStreet', request.addressStreet);
        _requireNonEmpty('addressHouseNumber', request.addressHouseNumber);
        _requireNonEmpty('addressZip', request.addressZip);
        _requireNonEmpty('addressCity', request.addressCity);
        _requireNonEmpty('registrationDate', request.registrationDate);
        _requireNonEmpty('verifyingContract', request.verifyingContract);
        _requirePositive('chainId', request.chainId);
        _requirePositive('addressCountry', request.addressCountry);
      case Eip7702SignRequest():
        _requireNonEmpty('expectedVerifyingContract', request.expectedVerifyingContract);
        _requireNonEmpty('expectedDelegator', request.expectedDelegator);
        _requirePositive('expectedChainId', request.expectedChainId);
        if (request.expectedAmount <= BigInt.zero) {
          throw const SignRequestValidationException(
            field: 'expectedAmount',
            reason: 'expected amount must be positive wei',
          );
        }
      case BtcPsbtSignRequest():
        if (request.psbtBytes.isEmpty) {
          throw const SignRequestValidationException(
            field: 'psbtBytes',
            reason: 'PSBT payload is empty',
          );
        }
      case EthTransferSignRequest():
        if (request.payload.isEmpty) {
          throw const SignRequestValidationException(
            field: 'payload',
            reason: 'ETH transfer payload is empty',
          );
        }
        _requirePositive('chainId', request.chainId);
        if (request.isEIP1559 && request.payload[0] != 0x02) {
          // F-040 — refuse to strip the type byte unless it is actually
          // the EIP-2718 `0x02` envelope. A caller that mislabels a
          // legacy payload would otherwise sign a corrupted hash.
          throw Eip1559TypeMismatchException(actualByte: request.payload[0]);
        }
    }
  }

  void _requireNonEmpty(String field, String value) {
    if (value.trim().isEmpty) {
      throw SignRequestValidationException(field: field, reason: 'must not be empty');
    }
  }

  void _requirePositive(String field, int value) {
    if (value <= 0) {
      throw SignRequestValidationException(field: field, reason: 'must be positive (>0)');
    }
  }

  // -------------------------------------------------------------------------
  // _romanise — toBitboxSafeAscii on every user string
  // -------------------------------------------------------------------------

  SignRequest _romanise(SignRequest request) {
    switch (request) {
      case RegistrationSignRequest():
        return RegistrationSignRequest(
          credentials: request.credentials,
          chainId: request.chainId,
          verifyingContract: request.verifyingContract,
          email: toBitboxSafeAscii(request.email),
          name: toBitboxSafeAscii(request.name),
          type: toBitboxSafeAscii(request.type),
          phoneNumber: toBitboxSafeAscii(request.phoneNumber),
          birthday: toBitboxSafeAscii(request.birthday),
          nationality: toBitboxSafeAscii(request.nationality),
          addressStreet: toBitboxSafeAscii(request.addressStreet),
          addressPostalCode: toBitboxSafeAscii(request.addressPostalCode),
          addressCity: toBitboxSafeAscii(request.addressCity),
          addressCountry: toBitboxSafeAscii(request.addressCountry),
          swissTaxResidence: request.swissTaxResidence,
          registrationDate: toBitboxSafeAscii(request.registrationDate),
          schema: request.schema,
        );
      case KycSignRequest():
        return KycSignRequest(
          credentials: request.credentials,
          chainId: request.chainId,
          verifyingContract: request.verifyingContract,
          accountType: toBitboxSafeAscii(request.accountType),
          firstName: toBitboxSafeAscii(request.firstName),
          lastName: toBitboxSafeAscii(request.lastName),
          phone: toBitboxSafeAscii(request.phone),
          addressStreet: toBitboxSafeAscii(request.addressStreet),
          addressHouseNumber: toBitboxSafeAscii(request.addressHouseNumber),
          addressZip: toBitboxSafeAscii(request.addressZip),
          addressCity: toBitboxSafeAscii(request.addressCity),
          addressCountry: request.addressCountry,
          registrationDate: toBitboxSafeAscii(request.registrationDate),
          schema: request.schema,
        );
      case Eip7702SignRequest():
        // EIP-7702 fields are hex addresses + bytes — already ASCII.
        // Romanise still runs idempotently for parity across entrypoints.
        return request;
      case BtcPsbtSignRequest():
        // PSBT bytes are not user strings. No-op.
        return request;
      case EthTransferSignRequest():
        // Raw transfer payload is bytes. No-op.
        return request;
    }
  }

  // -------------------------------------------------------------------------
  // _pinSchema — byte-equal compare backend types against client constant
  // -------------------------------------------------------------------------

  void _pinSchema(SignRequest request) {
    switch (request) {
      case RegistrationSignRequest():
        // Registration constructs the envelope from the schema constant
        // itself, so there is no backend-supplied `types` to compare.
        // The schema reference still drives _submitToBitbox.
        return;
      case KycSignRequest():
        return;
      case Eip7702SignRequest():
        _pinEip7702(request);
      case BtcPsbtSignRequest():
        request.schema.validatePsbt(request.psbtBytes);
      case EthTransferSignRequest():
        return;
    }
  }

  void _pinEip7702(Eip7702SignRequest request) {
    final data = request.eip7702Data;

    // Compare expected pinned parameters first — F-039 closure. A
    // mismatch on any of these is a hard reject; the backend has either
    // moved or has been MITM-ed.
    if (data.domain.verifyingContract.toLowerCase() !=
        request.expectedVerifyingContract.toLowerCase()) {
      throw Eip7702ExpectedParamsMismatchException(
        parameter: 'verifyingContract',
        expected: request.expectedVerifyingContract,
        actual: data.domain.verifyingContract,
      );
    }
    if (data.domain.chainId != request.expectedChainId) {
      throw Eip7702ExpectedParamsMismatchException(
        parameter: 'chainId',
        expected: '${request.expectedChainId}',
        actual: '${data.domain.chainId}',
      );
    }
    if (data.message.delegator.toLowerCase() != request.expectedDelegator.toLowerCase()) {
      throw Eip7702ExpectedParamsMismatchException(
        parameter: 'delegator',
        expected: request.expectedDelegator,
        actual: data.message.delegator,
      );
    }
    final actualWei = BigInt.tryParse(data.amountWei);
    if (actualWei == null || actualWei != request.expectedAmount) {
      throw Eip7702ExpectedParamsMismatchException(
        parameter: 'amountWei',
        expected: '${request.expectedAmount}',
        actual: data.amountWei,
      );
    }

    // Byte-equal compare the backend-supplied EIP-712 `types` against
    // the client-pinned schema constant — F-038 closure. Build a
    // canonical map from the DTO and hand it to the schema's
    // [Eip712Schema.validate]; any extra / missing / reordered field
    // raises [Eip712SchemaDriftException] before the BitBox sees a byte.
    final backendTypes = <String, dynamic>{
      'EIP712Domain': const [
        {'name': 'name', 'type': 'string'},
        {'name': 'version', 'type': 'string'},
        {'name': 'chainId', 'type': 'uint256'},
        {'name': 'verifyingContract', 'type': 'address'},
      ],
      'Delegation': [
        for (final f in data.types.delegation) {'name': f.name, 'type': f.type},
      ],
      'Caveat': [
        for (final f in data.types.caveat) {'name': f.name, 'type': f.type},
      ],
    };
    request.schema.validate(backendTypes);
  }

  // -------------------------------------------------------------------------
  // _submitToBitbox — the sole callsite of the underlying plugin
  // -------------------------------------------------------------------------

  Future<SignResult> _submitToBitbox(SignRequest request) async {
    switch (request) {
      case RegistrationSignRequest():
        return _submitRegistration(request);
      case KycSignRequest():
        return _submitKyc(request);
      case Eip7702SignRequest():
        return _submitEip7702(request);
      case BtcPsbtSignRequest():
        // TODO Initiative IV: route via WalletIsolate. For now the PSBT
        // sign is wired through the existing BitboxCredentials path; the
        // production BTC sign currently lives outside this pipeline.
        return BtcPsbtSignResult(request.psbtBytes);
      case EthTransferSignRequest():
        final sig = await request.credentials.signToSignature(
          request.payload,
          chainId: request.chainId,
          isEIP1559: request.isEIP1559,
        );
        return EthTransferSignResult(sig);
    }
  }

  Future<TypedDataSignResult> _submitRegistration(RegistrationSignRequest r) async {
    final message = <String, dynamic>{
      'email': r.email,
      'name': r.name,
      'type': r.type,
      'phoneNumber': r.phoneNumber,
      'birthday': r.birthday,
      'nationality': r.nationality,
      'addressStreet': r.addressStreet,
      'addressPostalCode': r.addressPostalCode,
      'addressCity': r.addressCity,
      'addressCountry': r.addressCountry,
      'swissTaxResidence': r.swissTaxResidence,
      'registrationDate': r.registrationDate,
      'walletAddress': r.credentials.address.hexEip55,
    };
    final domain = _registrationDomain(r);
    final typedDataMap = <String, dynamic>{
      'types': r.schema.typesAsJson(),
      'primaryType': r.schema.primaryType,
      'domain': domain,
      'message': message,
    };
    final envelopeJson = jsonEncode(typedDataMap);
    final dtoJson = jsonEncode(message);
    final signature = await eip712Signer.signTypedDataEnvelope(
      credentials: r.credentials,
      chainId: r.chainId,
      jsonEnvelope: envelopeJson,
    );
    return TypedDataSignResult(
      signature: signature,
      envelopeJson: envelopeJson,
      dtoJson: dtoJson,
    );
  }

  Map<String, dynamic> _registrationDomain(RegistrationSignRequest r) {
    // V1 domain includes chainId + verifyingContract; V0 has just
    // name+version (the legacy backend-rollout window). Detect by the
    // schema's EIP712Domain field list rather than a hard-coded type
    // check, so injecting any future schema variant just works.
    final hasChainId = r.schema.types['EIP712Domain']!
        .any((f) => f.name == 'chainId');
    final hasVerifyingContract = r.schema.types['EIP712Domain']!
        .any((f) => f.name == 'verifyingContract');
    return <String, dynamic>{
      'name': 'RealUnitUser',
      'version': '1',
      if (hasChainId) 'chainId': r.chainId,
      if (hasVerifyingContract) 'verifyingContract': r.verifyingContract,
    };
  }

  Future<TypedDataSignResult> _submitKyc(KycSignRequest r) async {
    final message = <String, dynamic>{
      'accountType': r.accountType,
      'firstName': r.firstName,
      'lastName': r.lastName,
      'phone': r.phone,
      'addressStreet': r.addressStreet,
      'addressHouseNumber': r.addressHouseNumber,
      'addressZip': r.addressZip,
      'addressCity': r.addressCity,
      'addressCountry': r.addressCountry,
      'walletAddress': r.credentials.address.hexEip55,
      'registrationDate': r.registrationDate,
    };
    final domain = <String, dynamic>{
      'name': 'RealUnitKyc',
      'version': '1',
      'chainId': r.chainId,
      'verifyingContract': r.verifyingContract,
    };
    final typedDataMap = <String, dynamic>{
      'types': r.schema.typesAsJson(),
      'primaryType': r.schema.primaryType,
      'domain': domain,
      'message': message,
    };
    final envelopeJson = jsonEncode(typedDataMap);
    final dtoJson = jsonEncode(message);
    final signature = await eip712Signer.signTypedDataEnvelope(
      credentials: r.credentials,
      chainId: r.chainId,
      jsonEnvelope: envelopeJson,
    );
    return TypedDataSignResult(
      signature: signature,
      envelopeJson: envelopeJson,
      dtoJson: dtoJson,
    );
  }

  Future<TypedDataSignResult> _submitEip7702(Eip7702SignRequest r) async {
    final data = r.eip7702Data;
    final message = <String, dynamic>{
      'delegate': data.message.delegate,
      'delegator': data.message.delegator,
      'authority': data.message.authority,
      'caveats': data.message.caveats,
      'salt': data.message.salt,
    };
    final domain = <String, dynamic>{
      'name': data.domain.name,
      'version': data.domain.version,
      'chainId': data.domain.chainId,
      'verifyingContract': data.domain.verifyingContract,
    };
    final typedDataMap = <String, dynamic>{
      'types': r.schema.typesAsJson(),
      'primaryType': r.schema.primaryType,
      'domain': domain,
      'message': message,
    };
    final envelopeJson = jsonEncode(typedDataMap);
    final dtoJson = jsonEncode(message);
    final signature = await eip712Signer.signTypedDataEnvelope(
      credentials: r.credentials,
      chainId: data.domain.chainId,
      jsonEnvelope: envelopeJson,
    );
    return TypedDataSignResult(
      signature: signature,
      envelopeJson: envelopeJson,
      dtoJson: dtoJson,
    );
  }
}
