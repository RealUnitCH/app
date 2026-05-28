import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/create_wallet/bloc/create_wallet_cubit.dart';
import 'package:realunit_wallet/screens/create_wallet/create_wallet_view.dart';

import '../../../helper/helper.dart';

class _MockCreateWalletCubit extends MockCubit<CreateWalletState> implements CreateWalletCubit {}

void main() {
  const seed =
      'cheese trigger cannon mention judge hire snack sustain annual predict illness celery';

  late _MockCreateWalletCubit cubit;
  late SeedDraft draft;

  setUpAll(() {
    stubNoScreenshotChannel();
  });

  setUp(() {
    cubit = _MockCreateWalletCubit();
    draft = SeedDraft(seed);
    when(() => cubit.state).thenReturn(CreateWalletState(draft: draft));
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

    goldenTest(
      'seed generated and revealed',
      fileName: 'create_wallet_page_revealed',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () {
        when(() => cubit.state).thenReturn(CreateWalletState(draft: draft, hideSeed: false));
        return wrapForGolden(buildSubject());
      },
    );
  });
}
