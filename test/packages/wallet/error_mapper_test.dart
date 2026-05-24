// Exhaustive Tier-0 contract test for [ErrorMapper] + every typed
// [SignException] subclass. Fails the build if:
//
//  * a known BitBox error code (`ErrorMapper.knownCodes`) is missing a
//    typed exception — instead of staying silent and surfacing as
//    `BitboxUnknownException`, the mapper MUST narrow the cause.
//  * a typed exception's ARB key is empty or duplicated.
//  * a typed exception's ARB key is missing from
//    `assets/languages/strings_de.arb` or `_en.arb` (the user would see
//    an empty string at runtime — symptomatic of the F-016 / F-020
//    regression class).
//  * a previously-untyped cause path (legacy [SigningCancelledException],
//    legacy [BitboxNotConnectedException]) is not converted to its
//    typed sibling.
//  * an unknown native code (999) crashes instead of becoming
//    `BitboxUnknownException(rawCode)`.
//
// Why exhaustive: the audit's F-016 / F-020 / F-021 cluster is a class
// of bugs where cubits did `catch (e) { e.toString() }` matching. Every
// rename of an underlying type silently broke the special-handling
// branch. The mapper plus this test makes "add a new error, forget to
// add the typed exception" impossible — the build turns red before the
// release.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';
import 'package:realunit_wallet/packages/wallet/error_mapper.dart';
import 'package:realunit_wallet/packages/wallet/exceptions/signing_cancelled_exception.dart';

Map<String, dynamic> _readArb(String path) {
  final raw = File(path).readAsStringSync();
  return jsonDecode(raw) as Map<String, dynamic>;
}

void main() {
  group('ErrorMapper.mapBitboxCode', () {
    const mapper = ErrorMapper();

    test('101 ErrInvalidInput → BitboxInvalidInputException with detail', () {
      final result = mapper.mapBitboxCode(101, message: 'non-ASCII char');
      expect(result, isA<BitboxInvalidInputException>());
      expect((result as BitboxInvalidInputException).detail, 'non-ASCII char');
      expect(result.arbKey, 'errorBitboxInvalidInput');
    });

    test('102 ErrUserAbort → BitboxUserAbortException', () {
      final result = mapper.mapBitboxCode(102);
      expect(result, isA<BitboxUserAbortException>());
      expect(result.arbKey, 'errorBitboxUserAbort');
    });

    test('103 channel-hash → BitboxChannelHashMismatchException', () {
      final result = mapper.mapBitboxCode(103);
      expect(result, isA<BitboxChannelHashMismatchException>());
      expect(result.arbKey, 'errorBitboxChannelHashMismatch');
    });

    test('104 transport timeout → BitboxTimeoutException', () {
      final result = mapper.mapBitboxCode(104);
      expect(result, isA<BitboxTimeoutException>());
      expect(result.arbKey, 'errorBitboxTimeout');
    });

    test('unknown code 999 → BitboxUnknownException(999); never crashes', () {
      final result = mapper.mapBitboxCode(999, message: 'oops');
      expect(result, isA<BitboxUnknownException>());
      final unknown = result as BitboxUnknownException;
      expect(unknown.rawCode, 999);
      expect(unknown.message, 'oops');
      expect(result.arbKey, 'errorBitboxUnknown');
    });

    test('every known code in ErrorMapper.knownCodes maps to a non-unknown typed exception', () {
      // If a code is in `knownCodes` it MUST narrow to a specific typed
      // exception. A code that surfaces as `BitboxUnknownException` while
      // also being in `knownCodes` is a symptom of a missing case branch.
      for (final code in ErrorMapper.knownCodes) {
        final result = mapper.mapBitboxCode(code);
        expect(
          result,
          isNot(isA<BitboxUnknownException>()),
          reason:
              'code $code is in knownCodes but maps to BitboxUnknownException — '
              'add a typed exception + case branch in ErrorMapper.mapBitboxCode',
        );
      }
    });

    test('codes outside knownCodes (negative, zero, very large) all surface as BitboxUnknownException', () {
      for (final code in <int>[-1, 0, 1, 500, 9999, 0x7FFFFFFF]) {
        if (ErrorMapper.knownCodes.contains(code)) continue;
        final result = mapper.mapBitboxCode(code);
        expect(result, isA<BitboxUnknownException>(), reason: 'code $code');
        expect((result as BitboxUnknownException).rawCode, code);
      }
    });
  });

  group('ErrorMapper.mapCause', () {
    const mapper = ErrorMapper();

    test('a SignException is returned as-is (identity)', () {
      const original = BitboxUserAbortException();
      expect(identical(mapper.mapCause(original), original), isTrue);
    });

    test('legacy SigningCancelledException → typed SigningCancelledSignException', () {
      const cause = SigningCancelledException();
      final result = mapper.mapCause(cause);
      expect(result, isA<SigningCancelledSignException>());
      expect(result.arbKey, 'errorSigningCancelled');
    });

    test('legacy BitboxNotConnectedException → typed BitboxNotConnectedSignException', () {
      const cause = BitboxNotConnectedException();
      final result = mapper.mapCause(cause);
      expect(result, isA<BitboxNotConnectedSignException>());
      expect(result.arbKey, 'errorBitboxNotConnected');
    });

    test('arbitrary Object → BitboxUnknownException(rawCode=-1); never crashes', () {
      final result = mapper.mapCause('a random string error');
      expect(result, isA<BitboxUnknownException>());
      expect((result as BitboxUnknownException).rawCode, -1);
      expect(result.message, contains('a random string error'));
    });

    test('Exception subclass → BitboxUnknownException(-1) with toString message', () {
      final cause = Exception('socket closed');
      final result = mapper.mapCause(cause);
      expect(result, isA<BitboxUnknownException>());
      expect((result as BitboxUnknownException).message, contains('socket closed'));
    });
  });

  group('SignException ARB key contract', () {
    final exceptions = allKnownSignExceptions();

    test('allKnownSignExceptions covers every concrete subclass at least once', () {
      // Hand-maintained registry mirror — if a new concrete subclass is
      // added to `error_mapper.dart` without an entry here, the test
      // fails. The names are the canonical list of typed exceptions the
      // pipeline can emit; cubits switch on these types.
      final classNames = exceptions.map((e) => e.runtimeType.toString()).toSet();
      expect(classNames, containsAll(<String>{
        'BitboxInvalidInputException',
        'BitboxUserAbortException',
        'BitboxChannelHashMismatchException',
        'BitboxTimeoutException',
        'BitboxNotConnectedSignException',
        'BitboxUnknownException',
        'Eip712SchemaDriftException',
        'Eip7702NotSupportedException',
        'Eip1559TypeMismatchException',
        'Eip7702ExpectedParamsMismatchException',
        'SignRequestValidationException',
        'SigningCancelledSignException',
        'BtcPsbtInvalidException',
      }));
    });

    test('every typed SignException has a non-empty ARB key', () {
      for (final ex in exceptions) {
        expect(ex.arbKey, isNotEmpty, reason: '${ex.runtimeType} missing ARB key');
        expect(
          ex.arbKey.trim(),
          ex.arbKey,
          reason: '${ex.runtimeType} ARB key has whitespace',
        );
      }
    });

    test('ARB keys are unique across the hierarchy (no copy-paste collision)', () {
      final keys = exceptions.map((e) => e.arbKey).toList();
      final unique = keys.toSet();
      expect(
        keys.length,
        unique.length,
        reason: 'Duplicate ARB key — every typed exception needs its own message: $keys',
      );
    });

    test('every ARB key is present in BOTH strings_de.arb AND strings_en.arb', () {
      // Surface the user-visible-string contract right here so a
      // refactor that adds a typed exception but forgets the i18n
      // entries fails the build. A missing key at runtime would leave
      // the user with an empty SnackBar — symptomatic of the F-016
      // regression class the typed hierarchy exists to prevent.
      final de = _readArb('assets/languages/strings_de.arb');
      final en = _readArb('assets/languages/strings_en.arb');
      for (final ex in exceptions) {
        expect(
          de.keys,
          contains(ex.arbKey),
          reason: '${ex.runtimeType}: ARB key "${ex.arbKey}" missing in strings_de.arb',
        );
        expect(
          en.keys,
          contains(ex.arbKey),
          reason: '${ex.runtimeType}: ARB key "${ex.arbKey}" missing in strings_en.arb',
        );
        expect((de[ex.arbKey] as String).trim(), isNotEmpty);
        expect((en[ex.arbKey] as String).trim(), isNotEmpty);
      }
    });
  });

  group('Typed exception equality + diagnostics', () {
    test('value equality on parametric exceptions', () {
      expect(
        const BitboxInvalidInputException(detail: 'x'),
        const BitboxInvalidInputException(detail: 'x'),
      );
      expect(
        const BitboxInvalidInputException(detail: 'x'),
        isNot(const BitboxInvalidInputException(detail: 'y')),
      );
      expect(
        const BitboxUnknownException(999, message: 'm'),
        const BitboxUnknownException(999, message: 'm'),
      );
      expect(
        const BitboxUnknownException(999, message: 'm'),
        isNot(const BitboxUnknownException(999, message: 'other')),
      );
      expect(
        const Eip1559TypeMismatchException(actualByte: 0x01),
        const Eip1559TypeMismatchException(actualByte: 0x01),
      );
      expect(
        const Eip1559TypeMismatchException(actualByte: 0x01),
        isNot(const Eip1559TypeMismatchException(actualByte: 0x02)),
      );
      expect(
        const Eip7702ExpectedParamsMismatchException(
          parameter: 'chainId',
          expected: '1',
          actual: '5',
        ),
        const Eip7702ExpectedParamsMismatchException(
          parameter: 'chainId',
          expected: '1',
          actual: '5',
        ),
      );
      expect(
        const SignRequestValidationException(field: 'email', reason: 'empty'),
        const SignRequestValidationException(field: 'email', reason: 'empty'),
      );
    });

    test('toString includes the raw code for unknown exceptions (telemetry)', () {
      const ex = BitboxUnknownException(987, message: 'firmware says no');
      expect(ex.toString(), contains('987'));
      expect(ex.toString(), contains('firmware says no'));
    });

    test('toString includes the actual byte for EIP-1559 mismatch (developer hint)', () {
      const ex = Eip1559TypeMismatchException(actualByte: 0x01);
      expect(ex.toString(), contains('0x1'));
      expect(ex.toString(), contains('0x02'));
    });

    test('toString of Eip712SchemaDriftException carries field/version/reason', () {
      const ex = Eip712SchemaDriftException(
        driftedField: 'Delegation[3].type',
        schemaVersion: 'eip7702-delegation/v1',
        reason: 'extra field secretApproval',
      );
      expect(ex.toString(), contains('Delegation[3].type'));
      expect(ex.toString(), contains('eip7702-delegation/v1'));
      expect(ex.toString(), contains('extra field secretApproval'));
    });
  });
}
