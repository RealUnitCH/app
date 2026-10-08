import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/hardware_wallet/cubit/move_balance_cubit.dart';
import 'package:realunit_wallet/screens/hardware_wallet/hardware_wallet_buy_page.dart';
import 'package:realunit_wallet/screens/hardware_wallet/hardware_wallet_intro_page.dart';
import 'package:realunit_wallet/screens/hardware_wallet/hardware_wallet_paired_page.dart';
import 'package:realunit_wallet/screens/hardware_wallet/hardware_wallet_setup_page.dart';
import 'package:realunit_wallet/screens/hardware_wallet/move_balance_page.dart';

import '../../../helper/helper.dart';

class _MockMoveBalanceCubit extends MockCubit<MoveBalanceState>
    implements MoveBalanceCubit {}

void main() {
  group('$HardwareWalletIntroPage', () {
    goldenTest(
      'intro copy and move CTA',
      fileName: 'hardware_wallet_intro_page',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(const HardwareWalletIntroPage()),
    );
  });

  group('$HardwareWalletBuyPage', () {
    goldenTest(
      'shop links and suitable-device confirm',
      fileName: 'hardware_wallet_buy_page',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(const HardwareWalletBuyPage()),
    );
  });

  group('$HardwareWalletSetupPage', () {
    goldenTest(
      'set-up-in-BitBox-app copy',
      fileName: 'hardware_wallet_setup_page',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(const HardwareWalletSetupPage()),
    );
  });

  group('$HardwareWalletPairedPage', () {
    goldenTest(
      'register and continue after pairing',
      fileName: 'hardware_wallet_paired_page',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(const HardwareWalletPairedPage()),
    );
  });

  group('$MoveBalanceView', () {
    late _MockMoveBalanceCubit cubit;

    setUp(() {
      cubit = _MockMoveBalanceCubit();
    });

    goldenTest(
      'both directions with whole-share balances',
      fileName: 'move_balance_page',
      constraints: phoneConstraints,
      builder: () {
        const state = MoveBalanceInitial(softwareBalance: 10, bitboxBalance: 4);
        when(() => cubit.state).thenReturn(state);
        whenListen(
          cubit,
          const Stream<MoveBalanceState>.empty(),
          initialState: state,
        );
        return wrapForGolden(
          BlocProvider<MoveBalanceCubit>.value(
            value: cubit,
            child: const MoveBalanceView(),
          ),
        );
      },
    );

    goldenTest(
      'failure shows the API message',
      fileName: 'move_balance_page_failure',
      constraints: phoneConstraints,
      builder: () {
        const state = MoveBalanceFailure('Recipient is not a registered shareholder');
        when(() => cubit.state).thenReturn(state);
        whenListen(
          cubit,
          const Stream<MoveBalanceState>.empty(),
          initialState: state,
        );
        return wrapForGolden(
          BlocProvider<MoveBalanceCubit>.value(
            value: cubit,
            child: const MoveBalanceView(),
          ),
        );
      },
    );
  });
}
