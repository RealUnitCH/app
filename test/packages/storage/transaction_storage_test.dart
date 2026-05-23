import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/storage/database.dart';
import 'package:realunit_wallet/packages/storage/transaction_storage.dart';
import 'package:realunit_wallet/packages/utils/fast_hash.dart';

void main() {
  late AppDatabase db;

  const sender = '0x1111111111111111111111111111111111111111';
  const receiver = '0x2222222222222222222222222222222222222222';
  const wallet = '0xWalletWalletWalletWalletWalletWalletWalle';

  // Asset id mirrors `TransactionRepository`'s mapping: fastHash('chainId:address').
  final assetA = fastHash('1:0xAaaA');
  final assetB = fastHash('1:0xBbbB');

  Future<int> insertTx({
    required String txId,
    required int height,
    required DateTime timestamp,
    int chainId = 1,
    String senderAddr = sender,
    String receiverAddr = receiver,
    String amount = '0xff',
    int? asset,
    int type = 2,
    String note = '',
    String data = '',
  }) {
    return db.insertTransactions(
      height,
      txId,
      chainId,
      senderAddr,
      receiverAddr,
      amount,
      asset ?? assetA,
      type,
      note,
      data,
      timestamp,
    );
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('TransactionStorage extension', () {
    test('insertTransactions persists every column and returns the row id', () async {
      final ts = DateTime.utc(2025, 1, 1);

      final rowId = await db.insertTransactions(
        42, // height
        'tx-1', // txId
        1, // chainId
        sender,
        receiver,
        '0xdead',
        assetA,
        2, // type
        'hello',
        'world',
        ts,
      );

      expect(rowId, greaterThan(0));

      final row = await db.getTransaction('tx-1');
      expect(row, isNotNull);
      expect(row!.height, 42);
      expect(row.txId, 'tx-1');
      expect(row.chainId, 1);
      expect(row.senderAddress, sender);
      expect(row.receiverAddress, receiver);
      expect(row.amount, '0xdead');
      expect(row.asset, assetA);
      expect(row.type, 2);
      expect(row.note, 'hello');
      expect(row.data, 'world');
      // Drift stores DateTime as a UTC-seconds integer and reads it back as a
      // local-zone DateTime — compare instants, not the textual form.
      expect(row.timeStamp.isAtSameMomentAs(ts), isTrue);
    });

    test('updateTransaction with all fields rewrites the row identified by txId', () async {
      await insertTx(txId: 'tx-1', height: 1, timestamp: DateTime.utc(2025, 1, 1));

      final affected = await db.updateTransaction(
        'tx-1',
        height: 99,
        chainId: 7,
        senderAddress: '0xNewSender',
        receiverAddress: '0xNewReceiver',
        amount: '0xbeef',
        asset: assetB,
        type: 3,
        note: 'noted',
        data: 'data-payload',
        timeStamp: DateTime.utc(2026, 6, 1),
      );

      expect(affected, 1);

      final row = await db.getTransaction('tx-1');
      expect(row, isNotNull);
      expect(row!.height, 99);
      expect(row.chainId, 7);
      expect(row.senderAddress, '0xNewSender');
      expect(row.receiverAddress, '0xNewReceiver');
      expect(row.amount, '0xbeef');
      expect(row.asset, assetB);
      expect(row.type, 3);
      expect(row.note, 'noted');
      expect(row.data, 'data-payload');
      expect(
        row.timeStamp.isAtSameMomentAs(DateTime.utc(2026, 6, 1)),
        isTrue,
      );
    });

    test('updateTransaction with no fields is a no-op on row contents', () async {
      // Exercises the Value.absentIfNull branch for every column: passing
      // nothing must leave the row exactly as inserted.
      final ts = DateTime.utc(2025, 3, 15);
      await insertTx(
        txId: 'tx-noop',
        height: 5,
        timestamp: ts,
        amount: '0x10',
        note: 'keep',
        data: 'keep-data',
      );

      await db.updateTransaction('tx-noop');

      final row = await db.getTransaction('tx-noop');
      expect(row, isNotNull);
      expect(row!.height, 5);
      expect(row.amount, '0x10');
      expect(row.note, 'keep');
      expect(row.data, 'keep-data');
      expect(row.timeStamp.isAtSameMomentAs(ts), isTrue);
    });

    test('updateTransaction returns 0 when no row matches the txId', () async {
      final affected = await db.updateTransaction('does-not-exist', height: 1);
      expect(affected, 0);
    });

    test('getAllTokenTransactions filters by the fastHash-encoded asset id', () async {
      // The extension hashes 'chainId:address' itself and queries on that.
      // We insert rows with both the matching and a non-matching asset id
      // and check only the matching ones come back.
      const chainId = 1;
      const tokenAddress = '0xAaaA';
      final matchingAsset = fastHash('$chainId:$tokenAddress');
      final otherAsset = fastHash('$chainId:0xOther');

      await insertTx(
        txId: 'tx-match-1',
        height: 1,
        timestamp: DateTime.utc(2025, 1, 1),
        asset: matchingAsset,
      );
      await insertTx(
        txId: 'tx-match-2',
        height: 2,
        timestamp: DateTime.utc(2025, 1, 2),
        asset: matchingAsset,
      );
      await insertTx(
        txId: 'tx-miss',
        height: 3,
        timestamp: DateTime.utc(2025, 1, 3),
        asset: otherAsset,
      );

      final result = await db.getAllTokenTransactions(chainId, tokenAddress);

      expect(result.map((r) => r.txId).toSet(), {'tx-match-1', 'tx-match-2'});
    });

    test('getAllTokenTransactions returns empty list when no rows match', () async {
      final result = await db.getAllTokenTransactions(1, '0xUnknown');
      expect(result, isEmpty);
    });

    test('allTransactions orders by timeStamp descending', () async {
      await insertTx(txId: 'older', height: 1, timestamp: DateTime.utc(2025, 1, 1));
      await insertTx(txId: 'newer', height: 2, timestamp: DateTime.utc(2025, 1, 5));
      await insertTx(txId: 'middle', height: 3, timestamp: DateTime.utc(2025, 1, 3));

      final all = await db.allTransactions;
      expect(all.map((t) => t.txId).toList(), ['newer', 'middle', 'older']);
    });

    test('allTransactions returns empty list on empty table', () async {
      final all = await db.allTransactions;
      expect(all, isEmpty);
    });

    test('watchTransactions emits a snapshot whenever a row is inserted', () async {
      // Drive the stream deterministically: subscribe first, then insert,
      // then await the predicate match. `expectLater` pumps the event loop
      // itself so no wall-clock delay is required.
      final stream = db.watchTransactions();

      final settled = expectLater(
        stream,
        emitsThrough(
          predicate<List<TransactionData>>(
            (list) => list.length == 1 && list.single.txId == 'tx-watch',
          ),
        ),
      );

      await insertTx(
        txId: 'tx-watch',
        height: 1,
        timestamp: DateTime.utc(2025, 1, 1),
      );

      await settled;
    });

    test('watchTransactions snapshot is timeStamp-descending', () async {
      await insertTx(txId: 'older', height: 1, timestamp: DateTime.utc(2025, 1, 1));
      await insertTx(txId: 'newer', height: 2, timestamp: DateTime.utc(2025, 1, 2));

      final first = await db.watchTransactions().first;
      expect(first.map((t) => t.txId).toList(), ['newer', 'older']);
    });

    test('watchTransfersOfAssets emits only type==2 rows touching the wallet', () async {
      // Wallet is sender: matches.
      await insertTx(
        txId: 'tx-sent',
        height: 1,
        timestamp: DateTime.utc(2025, 1, 1),
        senderAddr: wallet,
        type: 2,
      );
      // Wallet is receiver: matches.
      await insertTx(
        txId: 'tx-received',
        height: 2,
        timestamp: DateTime.utc(2025, 1, 2),
        receiverAddr: wallet,
        type: 2,
      );
      // Different asset id → must NOT match.
      await insertTx(
        txId: 'tx-other-asset',
        height: 3,
        timestamp: DateTime.utc(2025, 1, 3),
        senderAddr: wallet,
        type: 2,
        asset: assetB,
      );
      // Wallet involved but type != 2 → must NOT match.
      await insertTx(
        txId: 'tx-wrong-type',
        height: 4,
        timestamp: DateTime.utc(2025, 1, 4),
        senderAddr: wallet,
        type: 3,
      );
      // Asset matches but wallet not involved → must NOT match.
      await insertTx(
        txId: 'tx-not-wallet',
        height: 5,
        timestamp: DateTime.utc(2025, 1, 5),
        type: 2,
      );

      final emitted = await db.watchTransfersOfAssets([assetA], wallet).first;

      // Newest-first by timestamp.
      expect(emitted.map((t) => t.txId).toList(), ['tx-received', 'tx-sent']);
    });

    test('watchTransfersOfAssetsLimit caps the result count', () async {
      for (var i = 0; i < 4; i++) {
        await insertTx(
          txId: 'tx-$i',
          height: i + 1,
          timestamp: DateTime.utc(2025, 1, i + 1),
          senderAddr: wallet,
          type: 2,
        );
      }

      final emitted = await db.watchTransfersOfAssetsLimit([assetA], wallet, 2).first;

      // Limit 2, newest first: tx-3 (Jan 4), tx-2 (Jan 3).
      expect(emitted, hasLength(2));
      expect(emitted.map((t) => t.txId).toList(), ['tx-3', 'tx-2']);
    });

    test('watchTransfersOfSavingsLimit emits only type 3 or 4 rows', () async {
      // type == 3 (savings add): matches.
      await insertTx(
        txId: 'tx-add',
        height: 1,
        timestamp: DateTime.utc(2025, 1, 1),
        senderAddr: wallet,
        type: 3,
      );
      // type == 4 (savings remove): matches.
      await insertTx(
        txId: 'tx-remove',
        height: 2,
        timestamp: DateTime.utc(2025, 1, 2),
        senderAddr: wallet,
        type: 4,
      );
      // type == 2 (transfer): must NOT match.
      await insertTx(
        txId: 'tx-transfer',
        height: 3,
        timestamp: DateTime.utc(2025, 1, 3),
        senderAddr: wallet,
        type: 2,
      );
      // Right type but wallet not involved → must NOT match.
      await insertTx(
        txId: 'tx-not-wallet',
        height: 4,
        timestamp: DateTime.utc(2025, 1, 4),
        type: 3,
      );

      final emitted = await db.watchTransfersOfSavingsLimit([assetA], wallet, 10).first;

      // Newest first.
      expect(emitted.map((t) => t.txId).toList(), ['tx-remove', 'tx-add']);
    });

    test('watchTransfersOfSavingsLimit respects the limit argument', () async {
      for (var i = 0; i < 3; i++) {
        await insertTx(
          txId: 'tx-$i',
          height: i + 1,
          timestamp: DateTime.utc(2025, 1, i + 1),
          senderAddr: wallet,
          type: 3,
        );
      }

      final emitted = await db.watchTransfersOfSavingsLimit([assetA], wallet, 1).first;

      expect(emitted, hasLength(1));
      // Newest first → tx-2 (Jan 3).
      expect(emitted.single.txId, 'tx-2');
    });

    test('getLatestTransactions defaults to limit 1 and returns the newest row', () async {
      await insertTx(txId: 'older', height: 1, timestamp: DateTime.utc(2025, 1, 1));
      await insertTx(txId: 'newer', height: 2, timestamp: DateTime.utc(2025, 1, 5));

      final latest = await db.getLatestTransactions();

      expect(latest, hasLength(1));
      expect(latest.single.txId, 'newer');
    });

    test('getLatestTransactions honours an explicit larger limit', () async {
      await insertTx(txId: 'older', height: 1, timestamp: DateTime.utc(2025, 1, 1));
      await insertTx(txId: 'newer', height: 2, timestamp: DateTime.utc(2025, 1, 2));
      await insertTx(txId: 'newest', height: 3, timestamp: DateTime.utc(2025, 1, 3));

      final latest = await db.getLatestTransactions(limit: 2);

      expect(latest.map((t) => t.txId).toList(), ['newest', 'newer']);
    });

    test('getLatestTransactions returns empty list when table is empty', () async {
      final latest = await db.getLatestTransactions();
      expect(latest, isEmpty);
    });

    test('getTransaction returns the row for an existing txId', () async {
      await insertTx(txId: 'tx-1', height: 1, timestamp: DateTime.utc(2025, 1, 1));

      final row = await db.getTransaction('tx-1');
      expect(row, isNotNull);
      expect(row!.txId, 'tx-1');
    });

    test('getTransaction returns null for an unknown txId', () async {
      final row = await db.getTransaction('nope');
      expect(row, isNull);
    });
  });
}
