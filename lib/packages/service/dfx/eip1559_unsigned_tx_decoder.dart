/// Minimal, purpose-built decoder for the unsigned EIP-1559 (type 2) ZCHF-transfer
/// (pay-leg) transaction the OCP pay backend hands the app to sign
/// (`PUT /v1/realunit/pay/unsigned-transaction`). It exists so the app can verify —
/// BEFORE signing the pay leg — that the raw ERC20-transfer bytes match the DTO's
/// accompanying metadata (`tokenAddress`, `recipient`, `amountWei`, `chainId`) and
/// that gas/fee fields stay within local caps, rather than blindly signing whatever
/// bytes come back. See `PayProcessCubit._validatePayUnsignedTx`.
///
/// Scope is the pay leg only. The earlier REALU→ZCHF swap leg
/// (`RealUnitSwapUnsignedTransactionDto`) is signed blind today: that DTO carries only
/// a raw `swap` hex string with no comparable recipient/amount/chainId metadata, so this
/// decoder is not applied to it (closing that gap needs a backend DTO extension).
///
/// This is intentionally narrow: it only understands the exact shape the backend produces
/// for the pay leg (a type-2 tx whose `data` is a plain ERC20 `transfer(address,uint256)`
/// call) and rejects (fail-closed) anything that does not match that shape, rather than
/// being a general-purpose Ethereum RLP/ABI library.
library;

import 'dart:typed_data';

import 'package:convert/convert.dart' as convert;
import 'package:realunit_wallet/packages/service/dfx/exceptions/payment/pay_exceptions.dart';

/// A decoded (still unsigned) EIP-1559 transaction — the fields this app needs to
/// cross-check against `RealUnitOcpPayUnsignedTransactionDto` and to apply local
/// gas/fee caps before signing the pay leg.
class DecodedEip1559Transaction {
  final BigInt chainId;

  /// EIP-1559 max priority fee per gas (wei), from RLP field index 2.
  final BigInt maxPriorityFeePerGas;

  /// EIP-1559 max fee per gas (wei), from RLP field index 3.
  final BigInt maxFeePerGas;

  /// Gas limit, from RLP field index 4.
  final BigInt gasLimit;

  /// The tx's `to` address, normalized to `0x` + 40 lowercase hex chars.
  final String to;

  /// The tx's native ETH value (wei). An ERC20 transfer must carry 0.
  final BigInt value;

  /// The tx's calldata, unparsed.
  final Uint8List data;

  const DecodedEip1559Transaction({
    required this.chainId,
    required this.maxPriorityFeePerGas,
    required this.maxFeePerGas,
    required this.gasLimit,
    required this.to,
    required this.value,
    required this.data,
  });
}

/// Decodes the RLP-encoded, unsigned, type-2 (EIP-1559) transaction hex the OCP pay backend
/// returns for the pay leg. Throws `PayUnsignedTxMismatchException` — never silently
/// truncates/pads/skips — on any structural anomaly, since a transaction the app cannot
/// fully parse is one it must refuse to sign.
abstract final class Eip1559UnsignedTxDecoder {
  static const _typeByte = 0x02;
  static const _fieldCount = 9;
  static const _maxPriorityFeePerGasFieldIndex = 2;
  static const _maxFeePerGasFieldIndex = 3;
  static const _gasLimitFieldIndex = 4;
  static const _toFieldIndex = 5;
  static const _valueFieldIndex = 6;
  static const _dataFieldIndex = 7;

  static DecodedEip1559Transaction decode(String rawTransaction) {
    final hex = rawTransaction.startsWith('0x')
        ? rawTransaction.substring(2)
        : rawTransaction;
    final Uint8List bytes;
    try {
      bytes = Uint8List.fromList(convert.hex.decode(hex));
    } on FormatException {
      throw const PayUnsignedTxMismatchException('unsigned tx is not valid hex');
    }

    if (bytes.isEmpty || bytes[0] != _typeByte) {
      throw const PayUnsignedTxMismatchException(
        'unsigned tx is not an EIP-1559 (type 2) transaction',
      );
    }

    final decoded = _decodeItem(bytes, 1);
    if (decoded.end != bytes.length) {
      throw const PayUnsignedTxMismatchException(
        'unsigned tx has trailing bytes after RLP decode',
      );
    }
    final root = decoded.value;
    if (root is! List<Object>) {
      throw const PayUnsignedTxMismatchException('unsigned tx RLP root is not a list');
    }
    if (root.length != _fieldCount) {
      throw PayUnsignedTxMismatchException(
        'unsigned tx has ${root.length} RLP fields, expected $_fieldCount',
      );
    }

    final to = root[_toFieldIndex];
    if (to is! Uint8List || to.length != 20) {
      throw const PayUnsignedTxMismatchException('unsigned tx "to" is not a 20-byte address');
    }
    final data = root[_dataFieldIndex];
    if (data is! Uint8List) {
      throw const PayUnsignedTxMismatchException('unsigned tx "data" is not a byte string');
    }
    final accessList = root[8];
    if (accessList is! List<Object>) {
      throw const PayUnsignedTxMismatchException('unsigned tx "accessList" is not an RLP list');
    }

    return DecodedEip1559Transaction(
      chainId: _asBigInt(root[0]),
      maxPriorityFeePerGas: _asBigInt(root[_maxPriorityFeePerGasFieldIndex]),
      maxFeePerGas: _asBigInt(root[_maxFeePerGasFieldIndex]),
      gasLimit: _asBigInt(root[_gasLimitFieldIndex]),
      to: '0x${convert.hex.encode(to)}',
      value: _asBigInt(root[_valueFieldIndex]),
      data: data,
    );
  }

  static BigInt _asBigInt(Object field) {
    if (field is! Uint8List) {
      throw const PayUnsignedTxMismatchException('unsigned tx field is not a byte string');
    }
    if (field.isEmpty) return BigInt.zero;
    return BigInt.parse(convert.hex.encode(field), radix: 16);
  }

  /// Decodes a single RLP item starting at [pos]. Returns the decoded value (`Uint8List` for a
  /// byte string, `List<Object>` for a list) and the index immediately after the item.
  static ({Object value, int end}) _decodeItem(Uint8List data, int pos) {
    if (pos >= data.length) {
      throw const PayUnsignedTxMismatchException('RLP: unexpected end of data');
    }
    final prefix = data[pos];
    if (prefix < 0x80) {
      return (value: Uint8List.fromList([prefix]), end: pos + 1);
    } else if (prefix < 0xb8) {
      final length = prefix - 0x80;
      final start = pos + 1;
      _requireBytes(data, start, length);
      return (value: data.sublist(start, start + length), end: start + length);
    } else if (prefix < 0xc0) {
      final lengthOfLength = prefix - 0xb7;
      final start = pos + 1;
      _requireBytes(data, start, lengthOfLength);
      final length = _bytesToLength(data.sublist(start, start + lengthOfLength));
      final start2 = start + lengthOfLength;
      _requireBytes(data, start2, length);
      return (value: data.sublist(start2, start2 + length), end: start2 + length);
    } else if (prefix < 0xf8) {
      final length = prefix - 0xc0;
      final start = pos + 1;
      _requireBytes(data, start, length);
      return _decodeListBody(data, start, start + length);
    } else {
      final lengthOfLength = prefix - 0xf7;
      final start = pos + 1;
      _requireBytes(data, start, lengthOfLength);
      final length = _bytesToLength(data.sublist(start, start + lengthOfLength));
      final start2 = start + lengthOfLength;
      _requireBytes(data, start2, length);
      return _decodeListBody(data, start2, start2 + length);
    }
  }

  static ({Object value, int end}) _decodeListBody(Uint8List data, int start, int end) {
    final items = <Object>[];
    var pos = start;
    while (pos < end) {
      final item = _decodeItem(data, pos);
      items.add(item.value);
      pos = item.end;
    }
    if (pos != end) {
      throw const PayUnsignedTxMismatchException('RLP: list body length mismatch');
    }
    return (value: items, end: end);
  }

  static void _requireBytes(Uint8List data, int start, int length) {
    if (start < 0 || length < 0 || start + length > data.length) {
      throw const PayUnsignedTxMismatchException('RLP: declared length exceeds available data');
    }
  }

  static int _bytesToLength(Uint8List bytes) {
    // Cap length-of-length at 4 bytes so `start + length` in long-form RLP branches
    // cannot overflow a 64-bit signed int (lengthOfLength=8 can encode ~2^63 and wrap
    // past `_requireBytes`, letting a raw RangeError escape from `sublist`).
    if (bytes.length > 4) {
      throw const PayUnsignedTxMismatchException(
        'RLP: declared length-of-length exceeds practical transaction size',
      );
    }
    var value = 0;
    for (final b in bytes) {
      value = (value << 8) | b;
    }
    return value;
  }
}

/// A decoded ERC20 `transfer(address,uint256)` call.
class DecodedErc20Transfer {
  /// Normalized to `0x` + 40 lowercase hex chars.
  final String recipient;
  final BigInt amountWei;

  const DecodedErc20Transfer({required this.recipient, required this.amountWei});
}

/// Decodes ERC20 `transfer(address,uint256)` calldata — the only shape the OCP pay backend ever
/// asks the app to sign for the pay leg. Anything else (wrong selector, wrong length, a
/// non-zero-padded address slot) is rejected, never partially parsed.
abstract final class Erc20TransferCalldataDecoder {
  static const _selector = [0xa9, 0x05, 0x9c, 0xbb]; // transfer(address,uint256)
  static const _calldataLength = 68; // 4 (selector) + 32 (address) + 32 (amount)

  static DecodedErc20Transfer decode(Uint8List data) {
    if (data.length != _calldataLength) {
      throw PayUnsignedTxMismatchException(
        'unsigned tx calldata is ${data.length} bytes, expected $_calldataLength '
        '(ERC20 transfer)',
      );
    }
    for (var i = 0; i < _selector.length; i++) {
      if (data[i] != _selector[i]) {
        throw const PayUnsignedTxMismatchException(
          'unsigned tx calldata is not an ERC20 transfer(address,uint256) call',
        );
      }
    }

    final addressWord = data.sublist(4, 36);
    for (var i = 0; i < 12; i++) {
      if (addressWord[i] != 0) {
        throw const PayUnsignedTxMismatchException(
          'unsigned tx calldata recipient slot is not zero-padded',
        );
      }
    }
    final recipient = '0x${convert.hex.encode(addressWord.sublist(12, 32))}';

    final amountWord = data.sublist(36, 68);
    final amountWei = BigInt.parse(convert.hex.encode(amountWord), radix: 16);

    return DecodedErc20Transfer(recipient: recipient, amountWei: amountWei);
  }
}
