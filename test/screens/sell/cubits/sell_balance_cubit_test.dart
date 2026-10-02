import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/repository/balance_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/screens/sell/cubits/sell_balance/sell_balance_cubit.dart';

class _MockBalanceRepository extends Mock implements BalanceRepository {}

class _MockAppStore extends Mock implements AppStore {}

class _FakeBalance extends Fake implements Balance {}

const _wallet = '0x000000000000000000000000000000000000beef';

void main() {
  late _MockBalanceRepository repo;
  late _MockAppStore appStore;
  late StreamController<Balance> controller;

  setUpAll(() {
    registerFallbackValue(_FakeBalance());
  });

  setUp(() {
    repo = _MockBalanceRepository();
    appStore = _MockAppStore();
    controller = StreamController<Balance>();
    when(() => appStore.apiConfig)
        .thenReturn(const ApiConfig(networkMode: NetworkMode.mainnet));
    when(() => appStore.primaryAddress).thenReturn(_wallet);
    when(() => repo.watchBalance(any())).thenAnswer((_) => controller.stream);
  });

  tearDown(() async {
    await controller.close();
  });

  Balance balanceOf(BigInt amount) => Balance(
        chainId: realUnitAsset.chainId,
        contractAddress: realUnitAsset.address,
        walletAddress: _wallet,
        balance: amount,
        asset: realUnitAsset,
      );

  Future<void> pushAndAwait(SellBalanceCubit cubit, BigInt amount) async {
    final ready = cubit.stream
        .firstWhere((b) => b.balance == amount)
        .timeout(const Duration(seconds: 1));
    controller.add(balanceOf(amount));
    await ready;
  }

  group('$SellBalanceCubit', () {
    test('initial state is a zero balance derived from appStore', () {
      final cubit = SellBalanceCubit(repo, appStore);

      expect(cubit.state.chainId, realUnitAsset.chainId);
      expect(cubit.state.contractAddress, realUnitAsset.address);
      expect(cubit.state.walletAddress, _wallet);
      expect(cubit.state.balance, BigInt.zero);
      expect(cubit.state.asset, realUnitAsset);
    });

    test('subscribes to BalanceRepository.watchBalance on init', () {
      SellBalanceCubit(repo, appStore);

      verify(() => repo.watchBalance(any())).called(1);
    });

    test('emits balance updates pushed through the repo stream', () async {
      final cubit = SellBalanceCubit(repo, appStore);

      final updated = Balance(
        chainId: realUnitAsset.chainId,
        contractAddress: realUnitAsset.address,
        walletAddress: _wallet,
        balance: BigInt.from(7000),
        asset: realUnitAsset,
      );
      final ready = cubit.stream.firstWhere((b) => b.balance == BigInt.from(7000));
      controller.add(updated);
      await ready.timeout(const Duration(seconds: 1));

      expect(cubit.state.balance, BigInt.from(7000));
    });

    test('close() cancels the subscription cleanly', () async {
      final cubit = SellBalanceCubit(repo, appStore);

      await cubit.close();

      expect(cubit.isClosed, isTrue);
    });

    test('emits a later Kauf amount (77994 then 85194)', () async {
      final cubit = SellBalanceCubit(repo, appStore);

      await pushAndAwait(cubit, BigInt.from(77994));
      expect(cubit.state.balance, BigInt.from(77994));

      await pushAndAwait(cubit, BigInt.from(85194));
      expect(cubit.state.balance, BigInt.from(85194));
    });

    test('emits a later Verkauf amount (85194 then 77994)', () async {
      final cubit = SellBalanceCubit(repo, appStore);

      await pushAndAwait(cubit, BigInt.from(85194));
      expect(cubit.state.balance, BigInt.from(85194));

      await pushAndAwait(cubit, BigInt.from(77994));
      expect(cubit.state.balance, BigInt.from(77994));
    });

    test('emits a later on-chain transferIn amount (77994 then 78094)', () async {
      final cubit = SellBalanceCubit(repo, appStore);

      await pushAndAwait(cubit, BigInt.from(77994));
      expect(cubit.state.balance, BigInt.from(77994));

      await pushAndAwait(cubit, BigInt.from(78094));
      expect(cubit.state.balance, BigInt.from(78094));
    });

    test('emits a later on-chain transferOut amount (85194 then 85094)', () async {
      final cubit = SellBalanceCubit(repo, appStore);

      await pushAndAwait(cubit, BigInt.from(85194));
      expect(cubit.state.balance, BigInt.from(85194));

      await pushAndAwait(cubit, BigInt.from(85094));
      expect(cubit.state.balance, BigInt.from(85094));
    });

    test('pushing the same amount twice does not throw', () async {
      final cubit = SellBalanceCubit(repo, appStore);
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
