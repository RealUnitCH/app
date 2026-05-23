import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/packages/repository/asset_repository.dart';
import 'package:realunit_wallet/packages/storage/database.dart';

void main() {
  late AppDatabase db;
  late AssetRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = AssetRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  const assetA = Asset(
    chainId: 1,
    address: '0x553C7f9C780316FC1D34b8e14ac2465Ab22a090B',
    name: 'RealUnit Token',
    symbol: 'REALU',
    decimals: 0,
  );

  const assetB = Asset(
    chainId: 11155111,
    address: '0x0add9824820508dd7992cbebb9f13fbe8e45a30f',
    name: 'RealUnit Token (Sepolia)',
    symbol: 'REALU',
    decimals: 0,
  );

  group('$AssetRepository', () {
    test('insertAsset persists a row and returns a positive rowid', () async {
      final rowId = await repo.insertAsset(assetA);

      expect(rowId, greaterThan(0));

      final fetched = await repo.getAsset(assetA.chainId, assetA.address);
      expect(fetched, isNotNull);
      expect(fetched!.chainId, assetA.chainId);
      expect(fetched.address, assetA.address);
      expect(fetched.name, assetA.name);
      expect(fetched.symbol, assetA.symbol);
      expect(fetched.decimals, assetA.decimals);
    });

    test('getAsset returns null when no row matches the (chainId, address) pair', () async {
      final fetched = await repo.getAsset(assetA.chainId, assetA.address);
      expect(fetched, isNull);
    });

    test('existsAsset returns false before insert and true after insert', () async {
      expect(await repo.existsAsset(assetA), isFalse);

      await repo.insertAsset(assetA);

      expect(await repo.existsAsset(assetA), isTrue);
    });

    test('saveAsset inserts a new asset', () async {
      await repo.saveAsset(assetA);

      expect(await repo.existsAsset(assetA), isTrue);
      expect((await repo.allAssets).length, 1);
    });

    test('saveAsset is a no-op when the asset already exists', () async {
      // This guards the `if (!exists) await insertAsset(...)` branch:
      // calling saveAsset twice must not raise the UNIQUE constraint on
      // the assets.id column.
      await repo.saveAsset(assetA);
      await repo.saveAsset(assetA);

      final all = await repo.allAssets;
      expect(all.length, 1);
    });

    test('updateAsset is callable and does not raise on an existing row', () async {
      // updateAsset only sets iconUrl to null today (see
      // `AssetRepository.updateAsset`). The contract is still that the
      // call succeeds for a present row, so assert that and the asset
      // remains intact.
      await repo.insertAsset(assetA);

      await repo.updateAsset(assetA);

      final fetched = await repo.getAsset(assetA.chainId, assetA.address);
      expect(fetched, isNotNull);
      expect(fetched!.address, assetA.address);
    });

    test('allAssets returns every inserted asset', () async {
      await repo.insertAsset(assetA);
      await repo.insertAsset(assetB);

      final all = await repo.allAssets;

      expect(all.length, 2);
      expect(all.map((a) => a.address), containsAll([assetA.address, assetB.address]));
    });

    test('allAssets returns an empty list on a fresh database', () async {
      expect(await repo.allAssets, isEmpty);
    });
  });
}
