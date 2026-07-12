import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/sell_bitbox/cubit/sell_bitbox_cubit.dart';
import 'package:realunit_wallet/screens/sell_bitbox/widgets/sell_bitbox_eth_step.dart';

import '../../../helper/helper.dart';

class _MockSellBitboxCubit extends MockCubit<SellBitboxState>
    implements SellBitboxCubit {}

Widget _host(SellBitboxCubit cubit) => BlocProvider<SellBitboxCubit>.value(
      value: cubit,
      child: const SellBitboxEthStep(),
    );

void main() {
  late _MockSellBitboxCubit cubit;

  setUp(() {
    cubit = _MockSellBitboxCubit();
  });

  group('$SellBitboxEthStep', () {
    testWidgets('CheckingEth: shows a CupertinoActivityIndicator', (tester) async {
      when(() => cubit.state).thenReturn(SellBitboxCheckingEth());

      await tester.pumpApp(_host(cubit));

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    });

    testWidgets('RequestingFaucet: also shows a CupertinoActivityIndicator',
        (tester) async {
      when(() => cubit.state).thenReturn(SellBitboxRequestingFaucet());

      await tester.pumpApp(_host(cubit));

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    });

    testWidgets('WaitingForEth: hourglass icon + disabled Next button',
        (tester) async {
      when(() => cubit.state).thenReturn(SellBitboxWaitingForEth());

      await tester.pumpApp(_host(cubit));

      expect(find.byIcon(Icons.hourglass_bottom_rounded), findsOneWidget);
      final next = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(next.onPressed, isNull);
    });

    testWidgets('EthReady: check_circle icon + enabled Next button', (tester) async {
      when(() => cubit.state).thenReturn(SellBitboxEthReady());

      await tester.pumpApp(_host(cubit));

      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
      final next = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(next.onPressed, isNotNull);
    });

    testWidgets('unrelated state: renders nothing (SizedBox.shrink)', (tester) async {
      when(() => cubit.state).thenReturn(SellBitboxPreparingSwap());

      await tester.pumpApp(_host(cubit));

      expect(find.byType(CupertinoActivityIndicator), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });
  });
}
