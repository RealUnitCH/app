import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/packages/repository/balance_repository.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/balance_cubit.dart';

import '../../helper/helper.dart';

class _MockBalanceRepository extends Mock implements BalanceRepository {}

const _address = '0x0000000000000000000000000000000000000001';

void main() {
  late _MockBalanceRepository repo;
  late StreamController<Balance> controller;

  Balance balanceOf(BigInt amount) => Balance(
        chainId: realUnitAsset.chainId,
        contractAddress: realUnitAsset.address,
        walletAddress: _address,
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
    controller = StreamController<Balance>.broadcast();
    when(() => repo.watchBalance(any())).thenAnswer((_) => controller.stream);
  });

  tearDown(() async {
    await controller.close();
  });

  testWidgets(
    'Kauf replaces the first Bestand amount on DashboardPortfolio (77994 then 85194)',
    (tester) async {
      await tester.pumpApp(
        BlocProvider(
          create: (_) => BalanceCubit(
            repo,
            asset: realUnitAsset,
            walletAddress: _address,
          ),
          child: Scaffold(
            body: BlocBuilder<BalanceCubit, Balance>(
              builder: (context, state) => Text('bestand-${state.balance}'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('bestand-0'), findsOne);

      controller.add(balanceOf(BigInt.from(77994)));
      await tester.pump();
      await tester.pump();

      expect(find.text('bestand-77994'), findsOne);
      expect(find.text('bestand-85194'), findsNothing);

      controller.add(balanceOf(BigInt.from(85194)));
      await tester.pump();
      await tester.pump();

      expect(find.text('bestand-85194'), findsOne);
      expect(find.text('bestand-77994'), findsNothing);
    },
  );
}
