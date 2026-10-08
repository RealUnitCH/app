import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/repository/balance_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/balance_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_faucet_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_hardware_transfer_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_transfer_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/show_bitbox_reconnect_sheet.dart';
import 'package:realunit_wallet/screens/hardware_wallet/cubit/move_balance_cubit.dart';
import 'package:realunit_wallet/screens/hardware_wallet/hardware_wallet_paired_page.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/scrollable_actions_layout.dart';

class MoveBalancePage extends StatelessWidget {
  const MoveBalancePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => MoveBalanceCubit(
      walletService: getIt<WalletService>(),
      balanceRepository: getIt<BalanceRepository>(),
      transferService: getIt<RealUnitTransferService>(),
      hardwareTransferService: getIt<RealUnitHardwareTransferService>(),
      faucetService: getIt<DfxFaucetService>(),
      appStore: getIt<AppStore>(),
      homeBloc: context.read<HomeBloc>(),
      balanceService: getIt<BalanceService>(),
    )..load(),
    child: const MoveBalanceView(),
  );
}

class MoveBalanceView extends StatelessWidget {
  const MoveBalanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.moveBalanceTitle)),
      body: SafeArea(
        child: BlocConsumer<MoveBalanceCubit, MoveBalanceState>(
          listener: (context, state) async {
            if (state is MoveBalanceDisconnected) {
              final reconnected = await showBitboxReconnectSheet(context);
              if (reconnected && context.mounted) {
                await context.read<MoveBalanceCubit>().retryAfterConnection();
              }
              return;
            }
            if (state is MoveBalanceRegistrationRequired) {
              context.pushNamed(AppRoutes.kyc);
            }
          },
          builder: (context, state) {
            if (state is MoveBalanceLoading || state is MoveBalanceConfirming) {
              return const Center(child: CupertinoActivityIndicator());
            }
            return Padding(
              padding: const .symmetric(horizontal: 20, vertical: 16),
              child: ScrollableActionsLayout(
                body: _MoveBalanceBody(state: state),
                actions: _actions(context, state, s),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _actions(BuildContext context, MoveBalanceState state, S s) {
    final cubit = context.read<MoveBalanceCubit>();
    if (state is MoveBalanceQuoteReady) {
      return [
        AppFilledButton(label: s.confirm, onPressed: cubit.confirm),
      ];
    }
    if (state is MoveBalanceNeedEth) {
      return [
        AppFilledButton(
          label: s.retry,
          onPressed: cubit.retryPrepareBitboxToSoftware,
        ),
      ];
    }
    if (state is MoveBalanceFailure && state.canRetry) {
      return [
        AppFilledButton(label: s.retry, onPressed: cubit.confirm),
        if (state.direction != MoveBalanceDirection.softwareToBitbox)
          AppFilledButton(
            label: s.hardwareWalletRegisterAddress,
            variant: FilledButtonVariant.secondary,
            onPressed: () => registerBitboxAddress(context),
          ),
      ];
    }
    if (state is MoveBalanceFailure && state.reason == null) {
      return [
        AppFilledButton(
          label: s.hardwareWalletRegisterAddress,
          variant: FilledButtonVariant.secondary,
          onPressed: () => registerBitboxAddress(context),
        ),
      ];
    }
    return [];
  }
}

class _MoveBalanceBody extends StatelessWidget {
  const _MoveBalanceBody({required this.state});

  final MoveBalanceState state;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cubit = context.read<MoveBalanceCubit>();
    final softwareBalance = _softwareBalance(state);
    final bitboxBalance = _bitboxBalance(state);
    final current = state;
    return Column(
      crossAxisAlignment: .stretch,
      spacing: 16,
      children: [
        if (softwareBalance != null && bitboxBalance != null) ...[
          AppFilledButton(
            label: '${s.moveBalanceSoftwareToBitbox} · $softwareBalance REALU',
            variant: FilledButtonVariant.secondary,
            onPressed: cubit.prepareSoftwareToBitbox,
          ),
          AppFilledButton(
            label: '${s.moveBalanceBitboxToSoftware} · $bitboxBalance REALU',
            variant: FilledButtonVariant.secondary,
            onPressed: cubit.prepareBitboxToSoftware,
          ),
        ],
        if (current is MoveBalanceQuoteReady) ...[
          Text('${s.moveBalanceAmount}: ${current.amount} REALU'),
          if (current.ethPaysGas)
            Text(s.moveBalanceEthPaysGas)
          else
            Text('${s.fee}: ${current.networkFeeRealu} REALU'),
        ],
        if (current is MoveBalanceFailure) Text(_failureText(current, s)),
        if (current is MoveBalanceNeedEth) Text(current.message),
        if (current is MoveBalanceRegistrationRequired) Text(current.message),
        if (state is MoveBalanceSuccess) Text(s.moveBalanceSuccess),
      ],
    );
  }

  String _failureText(MoveBalanceFailure state, S s) => switch (state.reason) {
    MoveBalanceFailureReason.walletsMissing => s.moveBalanceWalletsMissing,
    MoveBalanceFailureReason.softwareEmpty => s.moveBalanceSoftwareEmpty,
    MoveBalanceFailureReason.bitboxEmpty => s.moveBalanceBitboxEmpty,
    MoveBalanceFailureReason.feeExceedsBalance => s.moveBalanceFeeExceedsBalance,
    MoveBalanceFailureReason.noQuote => s.moveBalanceNoQuote,
    MoveBalanceFailureReason.quoteMismatch => s.moveBalanceQuoteMismatch,
    null => state.message,
  };

  int? _softwareBalance(MoveBalanceState state) => switch (state) {
    MoveBalanceInitial(:final softwareBalance) => softwareBalance,
    MoveBalanceQuoteReady(:final softwareBalance) => softwareBalance,
    _ => null,
  };

  int? _bitboxBalance(MoveBalanceState state) => switch (state) {
    MoveBalanceInitial(:final bitboxBalance) => bitboxBalance,
    MoveBalanceQuoteReady(:final bitboxBalance) => bitboxBalance,
    _ => null,
  };
}
