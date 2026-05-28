// Tier-0 tests for the EIP-1559 type-byte assert (F-040).
//
// What this pins (Initiative II / ADR 0002 step 9):
//
//  * BitboxCredentials.signToSignature(payload, isEIP1559: true)
//    refuses to strip the leading byte unless `payload[0] == 0x02`.
//    A caller that mislabels a legacy transaction would otherwise sign
//    a corrupted hash; the typed Eip1559TypeMismatchException is the
//    contract the cubit / pipeline observes.
//  * SignPipeline._validate enforces the same invariant at the
//    pipeline boundary; mismatched type byte raises BEFORE the
//    underlying credentials path even sees the payload.
//  * Empty payload with isEIP1559=true is rejected by both layers
//    (defence in depth).
//
// The assert sits in both BitboxCredentials (direct callers — legacy
// transfer path) AND SignPipeline._validate (modern pipeline callers).
// The dual-pin matches the ADR's "defence in depth" principle: each
// trust boundary refuses on its own evidence.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_credentials.dart';
import 'package:realunit_wallet/packages/wallet/error_mapper.dart';
import 'package:realunit_wallet/packages/wallet/sign_pipeline.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  BitboxCredentials.resetSignQueue();

  group('BitboxCredentials.signToSignature: EIP-1559 type-byte assert (F-040)', () {
    test('payload[0] != 0x02 and isEIP1559=true → Eip1559TypeMismatchException', () async {
      final credentials = BitboxCredentials(
        '0x0000000000000000000000000000000000000001',
      );
      final payload = Uint8List.fromList([0x01, 0xaa, 0xbb, 0xcc]);
      expect(
        () => credentials.signToSignature(payload, chainId: 1, isEIP1559: true),
        throwsA(
          isA<Eip1559TypeMismatchException>().having((e) => e.actualByte, 'actualByte', 0x01),
        ),
      );
    });

    test(
      'payload empty and isEIP1559=true → Eip1559TypeMismatchException(actualByte=null)',
      () async {
        final credentials = BitboxCredentials(
          '0x0000000000000000000000000000000000000001',
        );
        expect(
          () => credentials.signToSignature(
            Uint8List(0),
            chainId: 1,
            isEIP1559: true,
          ),
          throwsA(
            isA<Eip1559TypeMismatchException>().having((e) => e.actualByte, 'actualByte', null),
          ),
        );
      },
    );

    test('payload[0] == 0x02 and isEIP1559=true passes the assert', () async {
      // Without a connected BitboxManager the sign throws
      // BitboxNotConnectedException; what we are pinning here is that
      // the type-byte assert does NOT fire — the failure comes from a
      // different layer, proving the assert lets the well-formed
      // payload through.
      final credentials = BitboxCredentials(
        '0x0000000000000000000000000000000000000001',
      );
      final payload = Uint8List.fromList([0x02, 0xaa, 0xbb]);
      expect(
        () => credentials.signToSignature(payload, chainId: 1, isEIP1559: true),
        throwsA(isNot(isA<Eip1559TypeMismatchException>())),
      );
    });

    test('isEIP1559=false skips the assert entirely (legacy path)', () async {
      final credentials = BitboxCredentials(
        '0x0000000000000000000000000000000000000001',
      );
      final payload = Uint8List.fromList([0x01, 0xaa]);
      expect(
        () => credentials.signToSignature(payload, chainId: 1, isEIP1559: false),
        throwsA(isNot(isA<Eip1559TypeMismatchException>())),
      );
    });
  });

  group('SignPipeline._validate: EIP-1559 type-byte assert (F-040)', () {
    const pipeline = SignPipeline();
    final credentials = EthPrivateKey.fromHex(
      'fb1ace12f9801e85f3db1b3935dd47d9f064f98152466f47c701b5e12680e612',
    );

    test('EthTransferSignRequest with payload[0]=0x01 and isEIP1559=true → '
        'Eip1559TypeMismatchException at validate boundary', () async {
      final request = EthTransferSignRequest(
        credentials: credentials,
        payload: Uint8List.fromList([0x01, 0xaa, 0xbb]),
        chainId: 1,
        isEIP1559: true,
      );
      await expectLater(
        pipeline.sign(request),
        throwsA(
          isA<Eip1559TypeMismatchException>().having((e) => e.actualByte, 'actualByte', 0x01),
        ),
      );
    });

    test('EthTransferSignRequest with empty payload → SignRequestValidationException', () async {
      // Empty payload trips the non-empty-payload validator before the
      // type-byte assert can run; the boundary refuses the request
      // structurally rather than diving into the 0x02 check.
      final request = EthTransferSignRequest(
        credentials: credentials,
        payload: Uint8List(0),
        chainId: 1,
        isEIP1559: true,
      );
      await expectLater(
        pipeline.sign(request),
        throwsA(isA<SignRequestValidationException>()),
      );
    });

    test('isEIP1559=false skips assert; legacy payload reaches the signer', () async {
      // No BitBox so EthPrivateKey signs raw; pinning that the assert
      // does NOT fire on legacy transfers.
      final request = EthTransferSignRequest(
        credentials: credentials,
        payload: Uint8List.fromList([0x01, 0xaa, 0xbb]),
        chainId: 1,
        isEIP1559: false,
      );
      final result = await pipeline.sign(request);
      expect(result, isA<EthTransferSignResult>());
    });
  });
}
