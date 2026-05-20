import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bitbox_flutter/bitbox_manager.dart';
import 'package:convert/convert.dart' as convert;
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class BitboxCredentials extends CredentialsWithKnownAddress {
  // Single device, single noise cipher — concurrent signs would advance the
  // nonce out of order and break decryption permanently.
  static Future<void> _signQueue = Future.value();

  final String _address;

  BitboxManager? bitboxManager;
  String? derivationPath;

  BitboxCredentials(this._address);

  static Future<T> _synchronizeSign<T>(Future<T> Function() sign) {
    final previous = _signQueue;
    final completer = Completer<void>();
    _signQueue = completer.future;

    return previous.then((_) async {
      try {
        return await sign();
      } finally {
        completer.complete();
      }
    });
  }

  @override
  EthereumAddress get address => EthereumAddress.fromHex(_address);

  void setBitbox(BitboxManager connection, [String? derivationPath_]) {
    bitboxManager = connection;
    derivationPath = derivationPath_ ?? "m/44'/60'/0'/0/0";
  }

  void clearBitbox() {
    bitboxManager = null;
    derivationPath = null;
  }

  @override
  MsgSignature signToEcSignature(Uint8List payload, {int? chainId, bool isEIP1559 = false}) =>
      throw UnimplementedError('EvmLedgerCredentials.signToEcSignature');

  @override
  Future<MsgSignature> signToSignature(
    Uint8List payload, {
    int? chainId,
    bool isEIP1559 = false,
  }) {
    return _synchronizeSign(() async {
      if (!isConnected) throw const BitboxNotConnectedException();

      if (isEIP1559) payload = payload.sublist(1);
      final sig = await bitboxManager!.signETHRLPTransaction(
        chainId ?? 1,
        derivationPath!,
        bytesToHex(payload),
        isEIP1559,
      );

      final r = bytesToHex(sig.sublist(0, 32));
      final s = bytesToHex(sig.sublist(32, 32 + 32));
      final v = sig.last.toInt();

      if (isEIP1559) {
        return MsgSignature(BigInt.parse(r, radix: 16), BigInt.parse(s, radix: 16), v);
      }

      var truncChainId = chainId ?? 1;
      while (truncChainId.bitLength > 32) {
        truncChainId >>= 8;
      }

      final truncTarget = truncChainId * 2 + 35;

      int parity = v;
      if (truncTarget & 0xff == v) {
        parity = 0;
      } else if ((truncTarget + 1) & 0xff == v) {
        parity = 1;
      }

      // https://github.com/ethereumjs/ethereumjs-util/blob/8ffe697fafb33cefc7b7ec01c11e3a7da787fe0e/src/signature.ts#L26
      final chainIdV = chainId != null ? (parity + (chainId * 2 + 35)) : parity;

      return MsgSignature(BigInt.parse(r, radix: 16), BigInt.parse(s, radix: 16), chainIdV);
    });
  }

  @override
  Future<Uint8List> signPersonalMessage(Uint8List payload, {int? chainId}) {
    return _synchronizeSign(() async {
      if (!isConnected) throw const BitboxNotConnectedException();
      return await bitboxManager!.signETHMessage(chainId ?? 1, derivationPath!, payload);
    });
  }

  @override
  Uint8List signPersonalMessageToUint8List(Uint8List payload, {int? chainId}) =>
      throw UnimplementedError('EvmLedgerCredentials.signPersonalMessageToUint8List');

  Future<String> signTypedDataV4(int chainId, String jsonData) {
    return _synchronizeSign(() async {
      if (!isConnected) throw const BitboxNotConnectedException();

      final signatureBytes = await bitboxManager!.signETHTypedMessage(
        chainId,
        derivationPath!,
        Uint8List.fromList(utf8.encode(jsonData)),
      );
      return '0x${convert.hex.encode(signatureBytes)}';
    });
  }

  bool get isConnected => bitboxManager != null;
}
