import 'package:alchemist/alchemist.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/eip7702/eip7702_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/real_unit_sell_payment_info_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/sell_payment_info.dart';
import 'package:realunit_wallet/screens/sell_bitbox/cubit/sell_bitbox_cubit.dart';
import 'package:realunit_wallet/screens/sell_bitbox/sell_bitbox_page.dart';
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
      'types': {
        'Delegation': <Map<String, dynamic>>[],
        'Caveat': <Map<String, dynamic>>[],
      },
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

SellPaymentInfo _paymentInfo() => SellPaymentInfo(
      id: 42,
      eip7702: Eip7702Data.fromJson(_eip7702Json()),
      amount: 100,
      exchangeRate: 1.0,
      rate: 1.0,
      beneficiary: const BeneficiaryDto(iban: 'CH...'),
      estimatedAmount: 100.0,
      currency: Currency.chf,
      depositAddress: '0xdeposit',
      tokenAddress: '0xtoken',
      chainId: 1,
      ethBalance: 1.0,
      requiredGasEth: 0.001,
    );

void main() {
  late _MockSellBitboxCubit cubit;

  setUp(() {
    cubit = _MockSellBitboxCubit();
    when(() => cubit.state).thenReturn(SellBitboxCheckingEth());
  });

  Widget buildSubject() => BlocProvider<SellBitboxCubit>.value(
        value: cubit,
        child: SellBitboxView(paymentInfo: _paymentInfo()),
      );

  group('$SellBitboxView', () {
    goldenTest(
      'checking eth initial step',
      fileName: 'sell_bitbox_page_default',
      // CupertinoActivityIndicator never settles; pump once to capture the
      // initial frame instead of letting pumpAndSettle hang.
      pumpBeforeTest: pumpOnce,
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(buildSubject()),
    );
  });
}
