import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/packages/service/dfx/models/transactions/dto/transactions_dto.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/balance_cubit.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/dashboard_bloc.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/pending_transactions_cubit.dart';
import 'package:realunit_wallet/screens/dashboard/dashboard_page.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/styles/currency.dart';

import '../../../helper/helper.dart';

class _MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState>
    implements DashboardBloc {}

class _MockBalanceCubit extends MockCubit<Balance> implements BalanceCubit {}

class _MockPendingTransactionsCubit extends MockCubit<List<TransactionDto>>
    implements PendingTransactionsCubit {}

void main() {
  late _MockDashboardBloc dashboardBloc;
  late _MockBalanceCubit balanceCubit;
  late _MockPendingTransactionsCubit pendingTxCubit;
  late MockSettingsBloc settingsBloc;

  Balance zeroBalance() => Balance(
        chainId: realUnitAsset.chainId,
        contractAddress: realUnitAsset.address,
        walletAddress: '0x0',
        balance: BigInt.zero,
        asset: realUnitAsset,
      );

  DashboardState emptyDashboardState() => DashboardState(
        price: BigInt.zero,
        priceChart: const [],
        portfolioHistory: const [],
        currency: Currency.chf,
      );

  setUp(() {
    dashboardBloc = _MockDashboardBloc();
    balanceCubit = _MockBalanceCubit();
    pendingTxCubit = _MockPendingTransactionsCubit();
    settingsBloc = MockSettingsBloc();

    when(() => dashboardBloc.state).thenReturn(emptyDashboardState());
    when(() => balanceCubit.state).thenReturn(zeroBalance());
    when(() => balanceCubit.asset).thenReturn(realUnitAsset);
    when(() => pendingTxCubit.state).thenReturn(const <TransactionDto>[]);
    when(() => settingsBloc.state).thenReturn(const SettingsState());
  });

  Widget buildSubject() => MultiBlocProvider(
        providers: [
          BlocProvider<SettingsBloc>.value(value: settingsBloc),
          BlocProvider<DashboardBloc>.value(value: dashboardBloc),
          BlocProvider<BalanceCubit>.value(value: balanceCubit),
          BlocProvider<PendingTransactionsCubit>.value(value: pendingTxCubit),
        ],
        child: const DashboardView(),
      );

  group('$DashboardView', () {
    goldenTest(
      'empty balance, no transactions',
      fileName: 'dashboard_empty',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(buildSubject()),
    );

    goldenTest(
      'with balance, no transactions',
      fileName: 'dashboard_with_balance',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () {
        when(() => balanceCubit.state).thenReturn(
          Balance(
            chainId: realUnitAsset.chainId,
            contractAddress: realUnitAsset.address,
            walletAddress: '0x0',
            balance: BigInt.from(5000000000000000000),
            asset: realUnitAsset,
          ),
        );
        return wrapForGolden(buildSubject());
      },
    );
  });
}
