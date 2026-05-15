import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/models/dfx_transaction.dart';
import 'package:realunit_wallet/models/transaction.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';

void main() {
  DfxTransaction build({
    int dfxId = 7,
    String? inputTxId,
    String? outputTxId,
    double? rate,
  }) =>
      DfxTransaction(
        dfxId: dfxId,
        rate: rate,
        inputTxId: inputTxId,
        outputTxId: outputTxId,
        height: 1,
        txId: '0xabc',
        chainId: realUnitAsset.chainId,
        senderAddress: '0x0',
        receiverAddress: '0x0',
        amount: BigInt.from(123),
        asset: realUnitAsset,
        type: TransactionTypes.tokenTransfer,
        note: null,
        data: null,
        timestamp: DateTime.utc(2026, 1, 1),
      );

  group('$DfxTransaction', () {
    test('is a Transaction subclass and inherits the base fields', () {
      final tx = build();

      expect(tx, isA<Transaction>());
      expect(tx.txId, '0xabc');
      expect(tx.amount, BigInt.from(123));
      expect(tx.asset, realUnitAsset);
    });

    test('carries the four DFX-only fields', () {
      final tx = build(
        dfxId: 42,
        rate: 1.05,
        inputTxId: '0xin',
        outputTxId: '0xout',
      );

      expect(tx.dfxId, 42);
      expect(tx.rate, 1.05);
      expect(tx.inputTxId, '0xin');
      expect(tx.outputTxId, '0xout');
    });

    test('rate / inputTxId / outputTxId are optional', () {
      final tx = build();

      expect(tx.rate, isNull);
      expect(tx.inputTxId, isNull);
      expect(tx.outputTxId, isNull);
    });
  });
}
