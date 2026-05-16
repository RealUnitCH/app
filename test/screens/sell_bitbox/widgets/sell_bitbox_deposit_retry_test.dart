import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/broadcast_transaction_request_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/eip7702/eip7702_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/real_unit_sell_payment_info_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/sell_payment_info.dart';
import 'package:realunit_wallet/screens/sell_bitbox/cubit/sell_bitbox_cubit.dart';
import 'package:realunit_wallet/screens/sell_bitbox/widgets/sell_bitbox_deposit_step.dart';
import 'package:realunit_wallet/screens/sell_bitbox/widgets/sell_bitbox_swap_step.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/currency.dart';

import '../../../helper/helper.dart';

class _MockSellBitboxCubit extends MockCubit<SellBitboxState>
    implements SellBitboxCubit {}

Map<String, dynamic> _eip7702Json() => {
      'relayerAddress': '0xrelay',
      'delegationManagerAddress': '0xmgr',
      'delegatorAddress': '0xdr',
      'userNonce': 7,
      'domain': {
        'name': 'RealUnit',
        'version': '1',
        'chainId': 1,
        'verifyingContract': '0xverify',
      },
      'types': {'Delegation': <Map<String, dynamic>>[], 'Caveat': <Map<String, dynamic>>[]},
      'message': {
        'delegate': '0xd',
        'delegator': '0xdr',
        'authority': '0xauth',
        'caveats': <Map<String, dynamic>>[],
        'salt': 0,
      },
      'tokenAddress': '0xtoken',
      'amountWei': '12345',
      'depositAddress': '0xdeposit',
    };

SellPaymentInfo _info() => SellPaymentInfo(
      id: 42,
      eip7702: Eip7702Data.fromJson(_eip7702Json()),
      amount: 100,
      exchangeRate: 1.0,
      rate: 1.0,
      beneficiary: const BeneficiaryDto(iban: 'CH...'),
      estimatedAmount: 99.5,
      currency: Currency.chf,
      depositAddress: '0xdeposit',
      tokenAddress: '0xtoken',
      chainId: 1,
      ethBalance: 0.1,
      requiredGasEth: 0.001,
    );

const _signed = BroadcastTransactionRequestDto(
  unsignedTx: '0xtx', r: '0xr', s: '0xs', v: 27,
);

void main() {
  late _MockSellBitboxCubit cubit;

  setUp(() {
    cubit = _MockSellBitboxCubit();
  });

  group('$SellBitboxDepositStep DepositRetry state', () {
    testWidgets('shows the red error icon + retry FilledButton', (tester) async {
      when(() => cubit.state).thenReturn(
        SellBitboxDepositRetry(_signed, _signed, 'rpc 502'),
      );

      await tester.pumpApp(BlocProvider<SellBitboxCubit>.value(
        value: cubit,
        child: SellBitboxDepositStep(paymentInfo: _info()),
      ));

      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.color, RealUnitColors.status.red600);

      // The retry FilledButton is enabled (non-null onPressed).
      final retry = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(retry.onPressed, isNotNull);
    });

    testWidgets('unrelated state: renders SizedBox.shrink (no content)',
        (tester) async {
      when(() => cubit.state).thenReturn(SellBitboxEthReady());

      await tester.pumpApp(BlocProvider<SellBitboxCubit>.value(
        value: cubit,
        child: SellBitboxDepositStep(paymentInfo: _info()),
      ));

      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });
  });

  group('$SellBitboxSwapStep fallback', () {
    testWidgets('unrelated state: renders SizedBox.shrink (no FilledButton, no spinner)',
        (tester) async {
      when(() => cubit.state).thenReturn(SellBitboxDepositing());

      await tester.pumpApp(BlocProvider<SellBitboxCubit>.value(
        value: cubit,
        child: SellBitboxSwapStep(paymentInfo: _info()),
      ));

      expect(find.byType(FilledButton), findsNothing);
    });
  });
}
