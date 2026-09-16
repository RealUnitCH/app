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

  Balance balanceOf(BigInt amount) => Balance(
        chainId: realUnitAsset.chainId,
        contractAddress: realUnitAsset.address,
        walletAddress: _address,
        balance: amount,
        asset: realUnitAsset,
      );

  Future<void> pushAndAwait(BalanceCubit cubit, BigInt amount) async {
    final ready = cubit.stream
        .firstWhere((b) => b.balance == amount)
        .timeout(const Duration(seconds: 1));
    controller.add(balanceOf(amount));
    await ready;
  }

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

    test('emits a later Kauf amount (77994 then 85194)', () async {
      final cubit = build();

      await pushAndAwait(cubit, BigInt.from(77994));
      expect(cubit.state.balance, BigInt.from(77994));

      await pushAndAwait(cubit, BigInt.from(85194));
      expect(cubit.state.balance, BigInt.from(85194));
    });

    test('emits a later Verkauf amount (85194 then 77994)', () async {
      final cubit = build();

      await pushAndAwait(cubit, BigInt.from(85194));
      expect(cubit.state.balance, BigInt.from(85194));

      await pushAndAwait(cubit, BigInt.from(77994));
      expect(cubit.state.balance, BigInt.from(77994));
    });

    test('emits a later on-chain transferIn amount (77994 then 78094)', () async {
      final cubit = build();

      await pushAndAwait(cubit, BigInt.from(77994));
      expect(cubit.state.balance, BigInt.from(77994));

      await pushAndAwait(cubit, BigInt.from(78094));
      expect(cubit.state.balance, BigInt.from(78094));
    });

    test('emits a later on-chain transferOut amount (85194 then 85094)', () async {
      final cubit = build();

      await pushAndAwait(cubit, BigInt.from(85194));
      expect(cubit.state.balance, BigInt.from(85194));

      await pushAndAwait(cubit, BigInt.from(85094));
      expect(cubit.state.balance, BigInt.from(85094));
    });

    test('pushing the same amount twice does not throw', () async {
      final cubit = build();
      final first = balanceOf(BigInt.from(77994));
      final second = balanceOf(BigInt.from(77994));

      final ready = cubit.stream
          .firstWhere((b) => b.balance == BigInt.from(77994))
          .timeout(const Duration(seconds: 1));
      controller.add(first);
      await ready;
      controller.add(second);

      expect(cubit.state.balance, BigInt.from(77994));
    });
  });
}
