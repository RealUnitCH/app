import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/storage/database.dart';
import 'package:realunit_wallet/packages/storage/transaction_storage.dart';
import 'package:realunit_wallet/packages/utils/fast_hash.dart';

void main() {
  // The high-level `TransactionRepository` is exhaustively tested in
  // `transaction_repository_test.dart`. This file only covers the
  // extension methods that the repository does not currently invoke,
  // so the static-only `transaction_storage.dart` API stays exercised.

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('TransactionStorage extension', () {
    test(
      'getAllTokenTransactions filters by the hashed (chainId, address) asset id',
      () async {
        const chainId = 1;
        const address = '0x553C7f9C780316FC1D34b8e14ac2465Ab22a090B';
        final assetId = fastHash('$chainId:$address');

        // One matching row.
        await db.insertTransactions(
          1,
          'tx-match',
          chainId,
          '0xA',
          '0xB',
          '0xff',
          assetId,
          0,
          '',
          '',
          DateTime.utc(2025, 1, 1),
        );
        // One row for a different asset → must be excluded.
        await db.insertTransactions(
          2,
          'tx-other',
          chainId,
          '0xA',
          '0xB',
          '0xff',
          assetId + 1,
          0,
          '',
          '',
          DateTime.utc(2025, 1, 1),
        );

        final rows = await db.getAllTokenTransactions(chainId, address);
        expect(rows.map((r) => r.txId), ['tx-match']);
      },
    );

    test('getAllTokenTransactions returns an empty list when nothing matches', () async {
      final rows = await db.getAllTokenTransactions(
        1,
        '0x0000000000000000000000000000000000000000',
      );
      expect(rows, isEmpty);
    });
  });
}
