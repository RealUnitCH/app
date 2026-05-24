// Typed-exception hierarchy + mapping for the SignPipeline.
//
// Why this file exists:
// F-003 / F-016 / F-020 / F-021 in the 2026-05-23 audit identified the same
// failure mode in multiple cubits — `catch (e) { e.toString() }` to route
// a user-visible error. Any refactor that renames the underlying exception
// type silently drops the special handling and the user sees a generic
// "registration failed". The audit's recommendation:
//
//   "Every BitBox SDK error code maps to a typed Dart exception with an
//    i18n key — operationalised by Initiative II."
//
// This file is the implementation:
//   * one base class `SignException` (declared in `exceptions/sign_exception.dart`)
//   * one typed subclass per code path the pipeline can throw
//   * one [ErrorMapper] that turns a raw cause (native error code, Object
//     from a catch site, native message) into a typed [SignException]
//   * an exhaustive test in `test/packages/wallet/error_mapper_test.dart`
//     fails the build if a new code is added without a typed exception.
//
// The ARB keys named below MUST exist in `assets/languages/strings_de.arb`
// and `_en.arb`; the exhaustive test asserts presence.

import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';
import 'package:realunit_wallet/packages/wallet/exceptions/eip712_schema_drift_exception.dart';
import 'package:realunit_wallet/packages/wallet/exceptions/sign_exception.dart';
import 'package:realunit_wallet/packages/wallet/exceptions/signing_cancelled_exception.dart';
import 'package:realunit_wallet/packages/wallet/schemas/btc_psbt_schema.dart';

export 'package:realunit_wallet/packages/wallet/exceptions/eip712_schema_drift_exception.dart';
export 'package:realunit_wallet/packages/wallet/exceptions/sign_exception.dart';
export 'package:realunit_wallet/packages/wallet/schemas/btc_psbt_schema.dart' show BtcPsbtInvalidException;

// ------------------------------------------------------------------------
// BitBox-side typed exceptions.
//
// The native BitBox SDK surfaces error codes (101 = `ErrInvalidInput`,
// etc.). The mapping table below converts each known code into a typed
// Dart exception. Unknown codes fall through to BitboxUnknownException —
// preserving the raw code lets support triage a new firmware error
// without crashing the cubit.
// ------------------------------------------------------------------------

/// 101 = `ErrInvalidInput` — the device refused the request because a
/// field violates its content rules (e.g. non-ASCII in an EIP-712 string,
/// payload too long).
class BitboxInvalidInputException extends SignException {
  final String? detail;
  const BitboxInvalidInputException({this.detail});
  @override
  String get arbKey => 'errorBitboxInvalidInput';
  @override
  String toString() => 'BitboxInvalidInputException(${detail ?? ""})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BitboxInvalidInputException && other.detail == detail);
  @override
  int get hashCode => detail.hashCode;
}

/// 102 = `ErrUserAbort` — the user pressed cancel on the device.
class BitboxUserAbortException extends SignException {
  const BitboxUserAbortException();
  @override
  String get arbKey => 'errorBitboxUserAbort';
  @override
  String toString() => 'BitboxUserAbortException';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BitboxUserAbortException;
  @override
  int get hashCode => (BitboxUserAbortException).hashCode;
}

/// 103 = channel hash mismatch — pairing channel-hash verify returned false.
class BitboxChannelHashMismatchException extends SignException {
  const BitboxChannelHashMismatchException();
  @override
  String get arbKey => 'errorBitboxChannelHashMismatch';
  @override
  String toString() => 'BitboxChannelHashMismatchException';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BitboxChannelHashMismatchException;
  @override
  int get hashCode => (BitboxChannelHashMismatchException).hashCode;
}

/// 104 = native side ran the BitBox SDK's transport timeout — surfaces as
/// a typed Dart exception so cubits can react with a reconnect prompt
/// rather than a generic failure.
class BitboxTimeoutException extends SignException {
  const BitboxTimeoutException();
  @override
  String get arbKey => 'errorBitboxTimeout';
  @override
  String toString() => 'BitboxTimeoutException';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BitboxTimeoutException;
  @override
  int get hashCode => (BitboxTimeoutException).hashCode;
}

/// Re-export of [BitboxNotConnectedException] under the [SignException]
/// umbrella so cubits can switch on `SignException` rather than juggling
/// two hierarchies. The original class lives in
/// `lib/packages/service/dfx/exceptions/bitbox_exception.dart` for
/// historical reasons; we wrap it.
class BitboxNotConnectedSignException extends SignException {
  const BitboxNotConnectedSignException();
  @override
  String get arbKey => 'errorBitboxNotConnected';
  @override
  String toString() => 'BitboxNotConnectedSignException';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BitboxNotConnectedSignException;
  @override
  int get hashCode => (BitboxNotConnectedSignException).hashCode;
}

/// Catch-all for native BitBox error codes the mapper does not yet know.
/// Carries the raw code so support has enough context to triage.
class BitboxUnknownException extends SignException {
  final int rawCode;
  final String? message;
  const BitboxUnknownException(this.rawCode, {this.message});
  @override
  String get arbKey => 'errorBitboxUnknown';
  @override
  String toString() => 'BitboxUnknownException(code=$rawCode, message=$message)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BitboxUnknownException && other.rawCode == rawCode && other.message == message);
  @override
  int get hashCode => Object.hash(rawCode, message);
}

// ------------------------------------------------------------------------
// Pipeline-side typed exceptions (non-BitBox).
// ------------------------------------------------------------------------

/// Raised when the device does not support EIP-7702 (older firmware).
class Eip7702NotSupportedException extends SignException {
  const Eip7702NotSupportedException();
  @override
  String get arbKey => 'errorEip7702NotSupported';
  @override
  String toString() => 'Eip7702NotSupportedException';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Eip7702NotSupportedException;
  @override
  int get hashCode => (Eip7702NotSupportedException).hashCode;
}

/// Raised when a payload labelled `isEIP1559: true` does NOT actually
/// start with the EIP-2718 type byte `0x02` — closes F-040. Without this
/// guard `signToSignature` would silently strip the first byte and the
/// device would sign a corrupted payload.
class Eip1559TypeMismatchException extends SignException {
  final int? actualByte;
  const Eip1559TypeMismatchException({this.actualByte});
  @override
  String get arbKey => 'errorEip1559TypeMismatch';
  @override
  String toString() {
    final byte = actualByte == null ? 'null' : '0x${actualByte!.toRadixString(16)}';
    return 'Eip1559TypeMismatchException(payload[0]=$byte, expected=0x02)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Eip1559TypeMismatchException && other.actualByte == actualByte);
  @override
  int get hashCode => actualByte.hashCode;
}

/// Raised when an EIP-7702 sell payload's expected pinned parameters
/// (verifyingContract / chainId / delegator / amount) do not match the
/// backend response — closes F-039. The pinning lives inside the signer
/// rather than in the caller (sell-service) so a future caller cannot
/// forget the validation step.
class Eip7702ExpectedParamsMismatchException extends SignException {
  final String parameter;
  final String expected;
  final String actual;
  const Eip7702ExpectedParamsMismatchException({
    required this.parameter,
    required this.expected,
    required this.actual,
  });
  @override
  String get arbKey => 'errorEip7702ExpectedParamsMismatch';
  @override
  String toString() =>
      'Eip7702ExpectedParamsMismatchException(parameter=$parameter, '
      'expected=$expected, actual=$actual)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Eip7702ExpectedParamsMismatchException &&
          other.parameter == parameter &&
          other.expected == expected &&
          other.actual == actual);
  @override
  int get hashCode => Object.hash(parameter, expected, actual);
}

/// Raised when a SignRequest's preconditions fail (empty required field,
/// invalid country symbol, missing wallet address, etc.). Carries the
/// field name for diagnostics; cubits use the ARB key.
class SignRequestValidationException extends SignException {
  final String field;
  final String reason;
  const SignRequestValidationException({required this.field, required this.reason});
  @override
  String get arbKey => 'errorSignRequestInvalid';
  @override
  String toString() => 'SignRequestValidationException(field=$field, reason=$reason)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SignRequestValidationException &&
          other.field == field &&
          other.reason == reason);
  @override
  int get hashCode => Object.hash(field, reason);
}

/// Raised when the user cancels the sign on the device (BitBox returns
/// empty signature `0x`) — kept as a typed `SignException` so cubits can
/// distinguish "user cancelled" from "device disconnected".
class SigningCancelledSignException extends SignException {
  const SigningCancelledSignException();
  @override
  String get arbKey => 'errorSigningCancelled';
  @override
  String toString() => 'SigningCancelledSignException';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SigningCancelledSignException;
  @override
  int get hashCode => (SigningCancelledSignException).hashCode;
}

// ------------------------------------------------------------------------
// ErrorMapper: the single boundary that turns raw causes into SignException.
// ------------------------------------------------------------------------

class ErrorMapper {
  const ErrorMapper();

  /// Known BitBox-side native error codes. Centralising them here means
  /// the exhaustive test in `error_mapper_test.dart` can iterate the
  /// table — if a new firmware error code is observed in production but
  /// not added here, the test stays green only because the mapper
  /// returned `BitboxUnknownException(code)`. Once a code is added to
  /// `knownCodes`, the test asserts a typed (non-unknown) mapping.
  static const knownCodes = <int>{101, 102, 103, 104};

  /// Maps a native BitBox error code to a typed [SignException].
  ///
  /// Codes are documented in `bitbox_flutter` `go/api/api.go` (mirrored
  /// from the upstream `bitbox02-api-go` source). The codes below are the
  /// stable subset observed in production:
  ///
  /// - 101 `ErrInvalidInput`  → [BitboxInvalidInputException]
  /// - 102 `ErrUserAbort`     → [BitboxUserAbortException]
  /// - 103 channel hash       → [BitboxChannelHashMismatchException]
  /// - 104 transport timeout  → [BitboxTimeoutException]
  ///
  /// Anything else surfaces as [BitboxUnknownException] with the raw code
  /// preserved.
  SignException mapBitboxCode(int code, {String? message}) {
    switch (code) {
      case 101:
        return BitboxInvalidInputException(detail: message);
      case 102:
        return const BitboxUserAbortException();
      case 103:
        return const BitboxChannelHashMismatchException();
      case 104:
        return const BitboxTimeoutException();
      default:
        return BitboxUnknownException(code, message: message);
    }
  }

  /// Turns an arbitrary [cause] caught in the pipeline into a
  /// [SignException]. The conversion is exhaustive over the known cause
  /// hierarchy:
  ///
  /// - already a [SignException]          → returned as-is
  /// - [SigningCancelledException] (legacy) → [SigningCancelledSignException]
  /// - [BitboxNotConnectedException] (legacy) → [BitboxNotConnectedSignException]
  ///
  /// Anything else becomes a [BitboxUnknownException] with rawCode = -1
  /// and the original `toString()` as the message — preserving the cause
  /// for telemetry without leaking it into the user-visible string.
  SignException mapCause(Object cause) {
    if (cause is SignException) return cause;
    if (cause is SigningCancelledException) {
      return const SigningCancelledSignException();
    }
    if (cause is BitboxNotConnectedException) {
      return const BitboxNotConnectedSignException();
    }
    return BitboxUnknownException(-1, message: cause.toString());
  }
}

// ------------------------------------------------------------------------
// Bookkeeping: the canonical list of every concrete SignException class.
// Used by the exhaustive ErrorMapper test to assert (a) every class has a
// non-empty ARB key, (b) every key is present in BOTH `strings_*.arb`
// files, (c) no key is shared between two classes (avoid copy-paste
// collisions).
// ------------------------------------------------------------------------

/// Helper for the exhaustiveness test to enumerate every typed exception
/// the pipeline can emit. New typed exceptions MUST be added here so the
/// test can assert their ARB key exists in both languages.
List<SignException> allKnownSignExceptions() {
  return const [
    BitboxInvalidInputException(),
    BitboxUserAbortException(),
    BitboxChannelHashMismatchException(),
    BitboxTimeoutException(),
    BitboxNotConnectedSignException(),
    BitboxUnknownException(0),
    Eip712SchemaDriftException(
      driftedField: 'Delegation[0]',
      schemaVersion: 'eip7702-delegation/v1',
      reason: 'extra field',
    ),
    Eip7702NotSupportedException(),
    Eip1559TypeMismatchException(),
    Eip7702ExpectedParamsMismatchException(
      parameter: 'chainId',
      expected: '1',
      actual: '5',
    ),
    SignRequestValidationException(field: 'email', reason: 'empty'),
    SigningCancelledSignException(),
    BtcPsbtInvalidException('empty'),
  ];
}
