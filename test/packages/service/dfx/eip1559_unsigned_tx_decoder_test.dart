import 'dart:typed_data';

import 'package:convert/convert.dart' as convert;
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/eip1559_unsigned_tx_decoder.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/payment/pay_exceptions.dart';

/// Independently verified (Python reference RLP round-trip) EIP-1559 type-2 unsigned
/// tx: chainId=11155111, to=0x1111…ac01, value=0, ERC20 transfer to 0x2222…bc02 for
/// amount=5000000000000000000.
const _validUnsignedTx =
    '0x02f87183aa36a7018459682f008504a817c800830186a094111111111111111111111111111111111111ac0180b844a9059cbb000000000000000000000000222222222222222222222222222222222222bc020000000000000000000000000000000000000000000000004563918244f40000c0';

const _validCalldataHex =
    'a9059cbb000000000000000000000000222222222222222222222222222222222222bc020000000000000000000000000000000000000000000000004563918244f40000';

void main() {
  group('Eip1559UnsignedTxDecoder.decode', () {
    test('decodes a valid EIP-1559 ERC20-transfer unsigned tx', () {
      final tx = Eip1559UnsignedTxDecoder.decode(_validUnsignedTx);

      expect(tx.chainId, BigInt.from(11155111));
      expect(tx.maxPriorityFeePerGas, BigInt.from(1500000000));
      expect(tx.maxFeePerGas, BigInt.from(20000000000));
      expect(tx.gasLimit, BigInt.from(100000));
      expect(tx.to, '0x111111111111111111111111111111111111ac01');
      expect(tx.value, BigInt.zero);
      expect(tx.data.length, 68);
      expect(convert.hex.encode(tx.data), _validCalldataHex);
    });

    test('rejects long-form RLP length-of-length > 4 with typed exception (not RangeError)', () {
      // type=0x02, then long-STRING prefix 0xbf (lengthOfLength = 0xbf - 0xb7 = 8)
      // followed by 8 length-bytes '7ffffffffffffffe' (0x7ffffffffffffffe = 9223372036854775806)
      // so start2+length overflows a signed 64-bit int and wraps negative; without the
      // length-of-length cap, _requireBytes lets it through and data.sublist throws a raw
      // RangeError; must stay typed as PayUnsignedTxMismatchException.
      expect(
        () => Eip1559UnsignedTxDecoder.decode('0x02bf7ffffffffffffffe'),
        throwsA(isA<PayUnsignedTxMismatchException>()),
      );
    });

    test('rejects a non-type-2 transaction', () {
      expect(
        () => Eip1559UnsignedTxDecoder.decode(
          '0x01f87183aa36a7018459682f008504a817c800830186a094111111111111111111111111111111111111ac0180b844a9059cbb000000000000000000000000222222222222222222222222222222222222bc020000000000000000000000000000000000000000000000004563918244f40000c0',
        ),
        throwsA(isA<PayUnsignedTxMismatchException>()),
      );
    });

    test('rejects trailing bytes after a complete RLP encoding', () {
      expect(
        () => Eip1559UnsignedTxDecoder.decode(
          '0x02f87183aa36a7018459682f008504a817c800830186a094111111111111111111111111111111111111ac0180b844a9059cbb000000000000000000000000222222222222222222222222222222222222bc020000000000000000000000000000000000000000000000004563918244f40000c0ff',
        ),
        throwsA(isA<PayUnsignedTxMismatchException>()),
      );
    });

    test('rejects a truncated encoding', () {
      expect(
        () => Eip1559UnsignedTxDecoder.decode(
          '0x02f87183aa36a7018459682f008504a817c800830186a094111111111111111111111111111111111111ac0180b844a9059cbb000000000000000000000000222222222222222222222222222222222222bc0200000000000000000000000000000000000000000000000045639182',
        ),
        throwsA(isA<PayUnsignedTxMismatchException>()),
      );
    });

    test('rejects a tx whose RLP root has the wrong field count (accessList stripped)', () {
      // Same tx as _validUnsignedTx but with the trailing accessList field (empty list `c0`)
      // removed and the outer list-length prefix corrected from 0x71 (113 bytes) to 0x70
      // (112 bytes) so the RLP still decodes cleanly with zero trailing bytes — root then has
      // 8 fields instead of 9. Verified byte-for-byte against a reference RLP decoder.
      expect(
        () => Eip1559UnsignedTxDecoder.decode(
          '0x02f87083aa36a7018459682f008504a817c800830186a094111111111111111111111111111111111111ac0180b844a9059cbb000000000000000000000000222222222222222222222222222222222222bc020000000000000000000000000000000000000000000000004563918244f40000',
        ),
        throwsA(
          isA<PayUnsignedTxMismatchException>().having(
            (e) => e.reason,
            'reason',
            'unsigned tx has 8 RLP fields, expected 9',
          ),
        ),
      );
    });

    test('rejects invalid hex', () {
      expect(
        () => Eip1559UnsignedTxDecoder.decode('0x02zzzz'),
        throwsA(isA<PayUnsignedTxMismatchException>()),
      );
    });

    test('rejects an empty string', () {
      expect(
        () => Eip1559UnsignedTxDecoder.decode(''),
        throwsA(isA<PayUnsignedTxMismatchException>()),
      );
    });
  });

  group('Erc20TransferCalldataDecoder.decode', () {
    test('decodes a valid transfer(address,uint256) call', () {
      final data = Uint8List.fromList(convert.hex.decode(_validCalldataHex));
      final transfer = Erc20TransferCalldataDecoder.decode(data);

      expect(transfer.recipient, '0x222222222222222222222222222222222222bc02');
      expect(transfer.amountWei, BigInt.parse('5000000000000000000'));
    });

    test('rejects a wrong function selector', () {
      final data = Uint8List.fromList(
        convert.hex.decode(
          'aaaaaaaa000000000000000000000000222222222222222222222222222222222222bc020000000000000000000000000000000000000000000000004563918244f40000',
        ),
      );
      expect(
        () => Erc20TransferCalldataDecoder.decode(data),
        throwsA(isA<PayUnsignedTxMismatchException>()),
      );
    });

    test('rejects wrong calldata length', () {
      final data = Uint8List.fromList(
        convert.hex.decode(
          'a9059cbb000000000000000000000000222222222222222222222222222222222222bc020000000000000000000000000000000000000000000000004563918244f400',
        ),
      );
      expect(
        () => Erc20TransferCalldataDecoder.decode(data),
        throwsA(isA<PayUnsignedTxMismatchException>()),
      );
    });

    test('rejects a non-zero-padded recipient address slot', () {
      final data = Uint8List.fromList(
        convert.hex.decode(
          'a9059cbb010000000000000000000000222222222222222222222222222222222222bc020000000000000000000000000000000000000000000000004563918244f40000',
        ),
      );
      expect(
        () => Erc20TransferCalldataDecoder.decode(data),
        throwsA(isA<PayUnsignedTxMismatchException>()),
      );
    });
  });
}
