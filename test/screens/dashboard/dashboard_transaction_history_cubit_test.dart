import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/models/transaction.dart';
import 'package:realunit_wallet/packages/repository/transaction_repository.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/dashboard_transaction_history_cubit.dart';

class _MockTransactionRepository extends Mock implements TransactionRepository {}

const _address = '0x0000000000000000000000000000000000000001';

Transaction _tx(String txId) => Transaction(
      height: 1,
      txId: txId,
      chainId: realUnitAsset.chainId,
      senderAddress: _address,
      receiverAddress: _address,
      amount: BigInt.one,
      asset: realUnitAsset,
      type: TransactionTypes.tokenTransfer,
      note: '',
      data: null,
      timestamp: DateTime.utc(2026, 1, 1),
    );

void main() {
  late _MockTransactionRepository repo;
  late StreamController<List<Transaction>> stream;

  setUp(() {
    repo = _MockTransactionRepository();
    stream = StreamController<List<Transaction>>();
    when(() => repo.watchTransactionsOfAssets(any(), any(), any()))
        .thenAnswer((_) => stream.stream);
  });

  tearDown(() async {
    await stream.close();
  });

  DashboardTransactionHistoryCubit build() => DashboardTransactionHistoryCubit(
        repo,
        asset: realUnitAsset,
        walletAddress: _address,
      );

  group('$DashboardTransactionHistoryCubit', () {
    test('initial state is an empty list', () {
      final cubit = build();

      expect(cubit.state, isEmpty);
    });

    test('subscribes with the asset, wallet address, and a limit of 3', () {
      build();

      verify(() => repo.watchTransactionsOfAssets([realUnitAsset], _address, 3))
          .called(1);
    });

    test('forwards each stream emission into state', () async {
      final cubit = build();
      final ready = cubit.stream.firstWhere((s) => s.length == 2);
      stream.add([_tx('a'), _tx('b')]);
      await ready.timeout(const Duration(seconds: 1));

      expect(cubit.state.map((t) => t.txId), ['a', 'b']);
    });

    test('close() cancels the subscription cleanly', () async {
      final cubit = build();

      await cubit.close();

      expect(cubit.isClosed, isTrue);
    });
  });
}
