import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/models/transaction.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/screens/transaction_history/completed_transaction.dart';

void main() {
  group('usableTxHash', () {
    test('returns null for null, empty, whitespace, and confirmed', () {
      expect(usableTxHash(null), isNull);
      expect(usableTxHash(''), isNull);
      expect(usableTxHash('   '), isNull);
      expect(usableTxHash('confirmed'), isNull);
    });

    test('returns the trimmed hash otherwise', () {
      expect(usableTxHash('0xabc'), '0xabc');
      expect(usableTxHash('  0xpay  '), '0xpay');
    });
  });

  group('buildFallbackTransaction', () {
    test(
      'sets sender, receiver, category, amount, empty txId, and timestamp',
      () {
        final timestamp = DateTime.utc(2026, 10, 8, 12);
        final tx = buildFallbackTransaction(
          asset: realUnitAsset,
          walletAddress: '0xwallet',
          txHash: 'confirmed',
          amount: BigInt.from(2),
          receiverAddress: '0xreceiver',
          category: TransferCategory.sale,
          timestamp: timestamp,
        );

        expect(tx.height, 0);
        expect(tx.txId, '');
        expect(tx.chainId, realUnitAsset.chainId);
        expect(tx.senderAddress, '0xwallet');
        expect(tx.receiverAddress, '0xreceiver');
        expect(tx.amount, BigInt.from(2));
        expect(tx.asset, realUnitAsset);
        expect(tx.type, TransactionTypes.tokenTransfer);
        expect(tx.category, TransferCategory.sale);
        expect(tx.note, '');
        expect(tx.data, isNull);
        expect(tx.timestamp, timestamp);
      },
    );

    test('uses the trimmed hash as txId when it is usable', () {
      final tx = buildFallbackTransaction(
        asset: realUnitAsset,
        walletAddress: '0xwallet',
        txHash: '  0xpay  ',
        amount: BigInt.one,
        receiverAddress: '0xreceiver',
        category: TransferCategory.transferOut,
        timestamp: DateTime.utc(2026, 10, 8),
      );

      expect(tx.txId, '0xpay');
      expect(tx.category, TransferCategory.transferOut);
    });
  });
}
