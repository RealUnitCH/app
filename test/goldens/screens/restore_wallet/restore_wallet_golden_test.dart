import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/restore_wallet/cubit/restore_wallet/restore_wallet_cubit.dart';
import 'package:realunit_wallet/screens/restore_wallet/cubit/validate_seed/validate_seed_cubit.dart';
import 'package:realunit_wallet/screens/restore_wallet/restore_wallet_view.dart';

import '../../../helper/helper.dart';

class _MockRestoreWalletCubit extends MockCubit<RestoreWalletState>
    implements RestoreWalletCubit {}

class _MockValidateSeedCubit extends MockCubit<ValidateSeedState>
    implements ValidateSeedCubit {}

void main() {
  late _MockRestoreWalletCubit restoreWalletCubit;
  late _MockValidateSeedCubit validateSeedCubit;
  late MockHomeBloc homeBloc;

  setUp(() {
    restoreWalletCubit = _MockRestoreWalletCubit();
    validateSeedCubit = _MockValidateSeedCubit();
    homeBloc = MockHomeBloc();
    when(() => restoreWalletCubit.state).thenReturn(const RestoreWalletState());
    when(() => validateSeedCubit.state).thenReturn(ValidateSeedState.uncomplete);
    when(() => homeBloc.state).thenReturn(const HomeState());
  });

  Widget buildSubject() => MultiBlocProvider(
        providers: [
          BlocProvider<HomeBloc>.value(value: homeBloc),
          BlocProvider<RestoreWalletCubit>.value(value: restoreWalletCubit),
          BlocProvider<ValidateSeedCubit>.value(value: validateSeedCubit),
        ],
        child: const RestoreWalletView(),
      );

  group('$RestoreWalletView', () {
    goldenTest(
      'default state',
      fileName: 'restore_wallet_page_default',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(buildSubject()),
    );
  });
}
