import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/repository/balance_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/screens/sell/cubits/sell_balance/sell_balance_cubit.dart';

import '../../helper/helper.dart';

class _MockBalanceRepository extends Mock implements BalanceRepository {}

class _MockAppStore extends Mock implements AppStore {}

const _wallet = '0x000000000000000000000000000000000000beef';

void main() {
  late _MockBalanceRepository repo;
  late _MockAppStore appStore;
  late StreamController<Balance> controller;

  Balance balanceOf(BigInt amount) => Balance(
        chainId: realUnitAsset.chainId,
        contractAddress: realUnitAsset.address,
        walletAddress: _wallet,
        balance: amount,
        asset: realUnitAsset,
      );

  setUpAll(() {
    registerFallbackValue(
      Balance(
        chainId: 1,
        contractAddress: '0x',
        walletAddress: '0x',
        balance: BigInt.zero,
        asset: realUnitAsset,
      ),
    );
  });

  setUp(() {
    repo = _MockBalanceRepository();
    appStore = _MockAppStore();
    controller = StreamController<Balance>.broadcast();

    when(() => appStore.apiConfig)
        .thenReturn(const ApiConfig(networkMode: NetworkMode.mainnet));
    when(() => appStore.primaryAddress).thenReturn(_wallet);
    when(() => repo.watchBalance(any())).thenAnswer((_) => controller.stream);
  });

  tearDown(() async {
    await controller.close();
  });

  testWidgets(
    'Verkauf updates Max to the later streamed holding (85194 then 77994)',
    (tester) async {
      await tester.pumpApp(
        BlocProvider(
          create: (_) => SellBalanceCubit(repo, appStore),
          child: Scaffold(
            body: BlocBuilder<SellBalanceCubit, Balance>(
              builder: (context, state) => Text('holding-${state.balance}'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('holding-0'), findsOne);

      controller.add(balanceOf(BigInt.from(85194)));
      await tester.pump();
      await tester.pump();
      expect(find.text('holding-85194'), findsOne);
      expect(find.text('holding-77994'), findsNothing);

      controller.add(balanceOf(BigInt.from(77994)));
      await tester.pump();
      await tester.pump();
      expect(find.text('holding-77994'), findsOne);
      expect(find.text('holding-85194'), findsNothing);
    },
  );
}
