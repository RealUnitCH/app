import 'package:alchemist/alchemist.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/create_wallet/bloc/create_wallet_cubit.dart';
import 'package:realunit_wallet/screens/create_wallet/create_wallet_view.dart';

import '../../../helper/helper.dart';

class _MockCreateWalletCubit extends MockCubit<CreateWalletState>
    implements CreateWalletCubit {}

class _MockWallet extends Mock implements SoftwareWallet {}

void main() {
  late _MockCreateWalletCubit cubit;

  setUp(() {
    cubit = _MockCreateWalletCubit();
    final wallet = _MockWallet();
    when(() => wallet.seed).thenReturn(
      'cheese trigger cannon mention judge hire snack sustain annual predict illness celery',
    );
    when(() => cubit.state).thenReturn(CreateWalletState(wallet: wallet));
  });

  Widget buildSubject() => BlocProvider<CreateWalletCubit>.value(
        value: cubit,
        child: const CreateWalletView(),
      );

  group('$CreateWalletView', () {
    goldenTest(
      'seed generated and blurred',
      fileName: 'create_wallet_page_default',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(buildSubject()),
    );
  });
}
