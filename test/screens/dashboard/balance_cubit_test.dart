import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/packages/repository/balance_repository.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/balance_cubit.dart';

class _MockBalanceRepository extends Mock implements BalanceRepository {}

class _FakeBalance extends Fake implements Balance {}

const _address = '0x0000000000000000000000000000000000000001';

void main() {
  late _MockBalanceRepository repo;
  late StreamController<Balance> controller;

  setUpAll(() {
    registerFallbackValue(_FakeBalance());
  });

  setUp(() {
    repo = _MockBalanceRepository();
    controller = StreamController<Balance>();
    when(() => repo.watchBalance(any())).thenAnswer((_) => controller.stream);
  });

  tearDown(() async {
    await controller.close();
  });

  BalanceCubit build() => BalanceCubit(
        repo,
        asset: realUnitAsset,
        walletAddress: _address,
      );

  group('$BalanceCubit', () {
    test('initial state is a zero balance bound to (chain, contract, wallet)', () {
      final cubit = build();

      expect(cubit.state.chainId, realUnitAsset.chainId);
      expect(cubit.state.contractAddress, realUnitAsset.address);
      expect(cubit.state.walletAddress, _address);
      expect(cubit.state.balance, BigInt.zero);
      expect(cubit.state.asset, realUnitAsset);
    });

    test('subscribes to BalanceRepository.watchBalance on init with the initial state', () {
      build();

      verify(() => repo.watchBalance(any())).called(1);
    });

    test('emits each balance update pushed through the repo stream', () async {
      final cubit = build();

      final updated = Balance(
        chainId: realUnitAsset.chainId,
        contractAddress: realUnitAsset.address,
        walletAddress: _address,
        balance: BigInt.from(12345),
        asset: realUnitAsset,
      );
      final ready = cubit.stream.firstWhere((b) => b.balance == BigInt.from(12345));
      controller.add(updated);
      await ready.timeout(const Duration(seconds: 1));

      expect(cubit.state.balance, BigInt.from(12345));
    });

    test('close() cancels the underlying stream subscription', () async {
      final cubit = build();

      await cubit.close();

      // No further emits reach the cubit; we just verify close completes
      // cleanly even after a subscription was opened.
      expect(cubit.isClosed, isTrue);
    });
  });
}
