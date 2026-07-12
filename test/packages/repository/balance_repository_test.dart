import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/packages/repository/balance_repository.dart';
import 'package:realunit_wallet/packages/storage/database.dart';

void main() {
  late AppDatabase db;
  late BalanceRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = BalanceRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  const asset = Asset(
    chainId: 1,
    address: '0x553C7f9C780316FC1D34b8e14ac2465Ab22a090B',
    name: 'RealUnit Token',
    symbol: 'REALU',
    decimals: 0,
  );
  const walletAddress = '0xabCDeF0123456789abCDeF0123456789aBCDeF01';

  Balance buildBalance({BigInt? amount}) => Balance(
    chainId: asset.chainId,
    contractAddress: asset.address,
    walletAddress: walletAddress,
    balance: amount ?? BigInt.from(123),
    asset: asset,
  );

  group('$BalanceRepository', () {
    test('insertBalance persists the row with a hex-encoded amount', () async {
      final balance = buildBalance(amount: BigInt.from(255));

      final rowId = await repo.insertBalance(balance);
      expect(rowId, greaterThan(0));

      final fetched = await repo.getBalance(asset, walletAddress);
      expect(fetched, isNotNull);
      // `BalanceRepository.getBalance` decodes the stored hex string back
      // to a BigInt — round-trip must preserve the value exactly.
      expect(fetched!.balance, BigInt.from(255));
      expect(fetched.chainId, asset.chainId);
      expect(fetched.contractAddress, asset.address);
      expect(fetched.walletAddress, walletAddress);
    });

    test('getBalance returns null when nothing matches the (asset, wallet) pair', () async {
      expect(await repo.getBalance(asset, walletAddress), isNull);
    });

    test('existsBalance flips from false to true after insert', () async {
      final balance = buildBalance();
      expect(await repo.existsBalance(balance), isFalse);

      await repo.insertBalance(balance);

      expect(await repo.existsBalance(balance), isTrue);
    });

    test('saveBalance inserts a new balance on first call', () async {
      await repo.saveBalance(buildBalance(amount: BigInt.from(100)));

      final fetched = await repo.getBalance(asset, walletAddress);
      expect(fetched, isNotNull);
      expect(fetched!.balance, BigInt.from(100));
    });

    test('saveBalance updates instead of inserting when the row already exists', () async {
      // The `exists ? updateBalance : insertBalance` branch is the
      // exact behaviour the rest of the wallet relies on for repeated
      // chain syncs; assert both halves end up in the same final state
      // without violating the unique id constraint.
      await repo.saveBalance(buildBalance(amount: BigInt.from(100)));
      await repo.saveBalance(buildBalance(amount: BigInt.from(200)));

      final fetched = await repo.getBalance(asset, walletAddress);
      expect(fetched, isNotNull);
      expect(fetched!.balance, BigInt.from(200));
    });

    test('updateBalance writes the new hex amount', () async {
      final original = buildBalance(amount: BigInt.from(100));
      await repo.insertBalance(original);

      original.balance = BigInt.from(0xdead);
      await repo.updateBalance(original);

      final fetched = await repo.getBalance(asset, walletAddress);
      expect(fetched, isNotNull);
      expect(fetched!.balance, BigInt.from(0xdead));
    });

    test('watchBalance emits a decoded Balance whenever the row changes', () async {
      final initial = buildBalance(amount: BigInt.from(1));
      await repo.insertBalance(initial);

      final stream = repo.watchBalance(initial);
      final emissions = <Balance>[];
      final sub = stream.listen(emissions.add);

      // First emission lands once the stream is hot.
      await Future<void>.delayed(Duration.zero);
      expect(emissions, isNotEmpty);
      expect(emissions.last.balance, BigInt.from(1));

      // A subsequent UPDATE must reach the listener with the new value.
      initial.balance = BigInt.from(2);
      await repo.updateBalance(initial);
      await Future<void>.delayed(Duration.zero);

      expect(emissions.last.balance, BigInt.from(2));

      await sub.cancel();
    });

    test('watchBalance suppresses emissions while the row does not exist yet', () async {
      // The `if (balanceData != null) sink.add(...)` guard means a stream
      // attached before the first insert must not emit a synthetic
      // initial Balance. Once the row appears via insertBalance the
      // listener receives the real value.
      final placeholder = buildBalance(amount: BigInt.from(1));

      final stream = repo.watchBalance(placeholder);
      final emissions = <Balance>[];
      final sub = stream.listen(emissions.add);

      await Future<void>.delayed(Duration.zero);
      expect(emissions, isEmpty);

      await repo.insertBalance(placeholder);
      await Future<void>.delayed(Duration.zero);

      expect(emissions, hasLength(1));
      expect(emissions.single.balance, BigInt.from(1));

      await sub.cancel();
    });
  });
}
