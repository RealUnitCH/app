import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/history/dto/pay_quote_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_pay_service.dart';
import 'package:realunit_wallet/screens/pay/cubits/pay_quote/pay_quote_cubit.dart';
import 'package:realunit_wallet/screens/pay/pay_process_page.dart';
import 'package:realunit_wallet/screens/pay/pay_quote_parts.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/transaction_history/completed_transaction.dart';
import 'package:realunit_wallet/screens/transaction_history/transaction_detail_page.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/currency.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/route_animation_gate.dart';
import 'package:realunit_wallet/widgets/scrollable_actions_layout.dart';

class PayQuotePage extends StatelessWidget {
  final String paymentLinkId;

  const PayQuotePage({super.key, required this.paymentLinkId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PayQuoteCubit(getIt<RealUnitPayService>(), paymentLinkId),
      child: RouteAnimationGate(
        onSettled: (c) => c.read<PayQuoteCubit>().load(),
        child: const PayQuoteView(),
      ),
    );
  }
}

class PayQuoteView extends StatelessWidget {
  const PayQuoteView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).payQuoteTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: BlocBuilder<PayQuoteCubit, PayQuoteState>(
            builder: (context, state) => switch (state) {
              PayQuoteLoading() => const Center(
                child: CupertinoActivityIndicator(),
              ),
              PayQuoteReady() => _PayQuoteReadyView(state: state),
              PayQuoteExpired() => _PayQuoteMessage(
                message: S.of(context).payFailureQuoteExpired,
              ),
              PayQuoteUnavailable() => _PayQuoteMessage(
                message: S.of(context).payQuoteUnavailable,
              ),
              PayQuoteError(:final message) => _PayQuoteMessage(
                message: message.isNotEmpty ? message : S.of(context).payFailureGeneric,
                onRetry: () => context.read<PayQuoteCubit>().load(),
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _PayQuoteReadyView extends StatefulWidget {
  final PayQuoteReady state;

  const _PayQuoteReadyView({required this.state});

  @override
  State<_PayQuoteReadyView> createState() => _PayQuoteReadyViewState();
}

class _PayQuoteReadyViewState extends State<_PayQuoteReadyView> {
  bool _navigating = false;
  Timer? _countdown;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _left(widget.state.expiresAt);
    if (_remaining > Duration.zero) {
      _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final left = _left(widget.state.expiresAt);
        setState(() => _remaining = left);
        if (left <= Duration.zero) _countdown?.cancel();
      });
    }
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  static Duration _left(DateTime expiresAt) {
    final left = expiresAt.difference(clock.now());
    return left.isNegative ? Duration.zero : left;
  }

  static String _clock(Duration remaining) {
    final total = remaining.inSeconds;
    final minutes = (total ~/ 60).toString().padLeft(2, '0');
    final seconds = (total % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining <= Duration.zero) {
      return _PayQuoteMessage(message: S.of(context).payFailureQuoteExpired);
    }
    final state = widget.state;
    final swap = state.swap;
    final feeChf = swap.ethereumTransactionFeeChf;
    final feeRealu = swap.ethereumTransactionFeeRealu;
    // The customer pays the network fee in REALU. DFX only fronts the gas.
    // A fee line is shown when the quote carries one. The signed quote itself
    // is not changed.
    final showFee = feeChf != null || feeRealu != null;
    final parts = payQuoteParts(
      billChf: state.fiatAmount,
      shares: swap.amount,
      proceedsChf: swap.estimatedAmount,
      feeChf: feeChf ?? 0,
      feeRealu: feeRealu ?? 0,
    );
    final merchant = state.merchantName;
    final settings = context.watch<SettingsBloc>().state;
    final useEur = settings.currency == Currency.eur && state.hasEurReceipt;
    // The till asked for this franc amount. It stays on the requested row
    // even when the receipt shows the stored euro figures.
    final requestedChf = formatPayFiat(parts.billChf, 'CHF');
    final feeFiat = useEur
        ? formatPayFiat(state.feeEur!, 'EUR')
        : formatPayFiat(parts.feeChf, 'CHF');
    final roundingFiat = useEur
        ? formatPayFiat(state.roundingEur!, 'EUR')
        : formatPayFiat(parts.roundingChf, 'CHF');
    final totalFiat = useEur
        ? formatPayFiat(state.totalEur!, 'EUR')
        : formatPayFiat(parts.totalChf, 'CHF');
    return ScrollableActionsLayout(
      centerBody: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 20,
        children: [
          if (merchant != null)
            Column(
              spacing: 2,
              children: [
                Text(
                  S.of(context).payQuoteMerchant,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: RealUnitColors.neutral500,
                  ),
                ),
                Text(
                  merchant,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          Column(
            spacing: 4,
            children: [
              Text(
                S.of(context).youSell,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: RealUnitColors.neutral500,
                ),
              ),
              Text(
                formatWholeRealu(swap.amount),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          PayQuoteReceiptCard(
            children: [
              PayQuoteAmountRow(
                label: S.of(context).payQuoteRequested,
                realu: formatPayRealu(parts.billRealu),
                chf: requestedChf,
                also: useEur ? formatPayFiat(state.billEur!, 'EUR') : null,
              ),
              if (showFee)
                PayQuoteAmountRow(
                  label: S.of(context).payQuoteRealuFees,
                  realu: formatPayRealu(parts.feeRealu),
                  chf: feeFiat,
                ),
              PayQuoteAmountRow(
                label: S.of(context).payQuoteRounding,
                realu: formatPayRealu(parts.roundingRealu),
                chf: roundingFiat,
              ),
              PayQuoteAmountRow(
                label: S.of(context).payQuoteTotal,
                realu: formatPayRealu(parts.totalRealu),
                chf: totalFiat,
              ),
            ],
          ),
          Text(
            _clock(_remaining),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      actions: [
        AppFilledButton(
          label: S.of(context).payConfirmButton,
          state: _navigating ? FilledButtonState.loading : FilledButtonState.idle,
          onPressed: _navigating
              ? null
              : () async {
                  if (_navigating) return;
                  setState(() => _navigating = true);
                  final navigator = Navigator.of(context);
                  Object? swapCompleted = false;
                  try {
                    swapCompleted = await navigator.push<Object>(
                      MaterialPageRoute<Object>(
                        builder: (_) => PayProcessPage(
                          paymentLinkId: state.paymentLinkId,
                          quoteId: state.quoteId,
                          swap: state.swap,
                        ),
                      ),
                    );
                  } finally {
                    // Only a typed pre-swap failure pops `false` and re-enables
                    // Pay. `true` (swap ran) and `null` (AppBar / system back)
                    // both leave this quote so REALU cannot be sold twice.
                    if (mounted && swapCompleted == false) {
                      setState(() => _navigating = false);
                    }
                  }
                  if (!context.mounted) return;
                  if (swapCompleted is PayProcessCompleted) {
                    final quote = PayQuoteDto(
                      merchantName: state.merchantName,
                      billChf: state.fiatAmount,
                      shares: swap.amount,
                      proceedsChf: swap.estimatedAmount,
                      feeChf: feeChf ?? 0,
                      feeRealu: feeRealu ?? 0,
                    );
                    final booked = await attachPayQuote(
                      swapCompleted.transaction,
                      quote,
                    );
                    if (!context.mounted) return;
                    context.goNamed(
                      AppRoutes.transactionDetail,
                      extra: TransactionDetailArgs(
                        transaction: booked,
                        walletAddress: swapCompleted.walletAddress,
                        returnToDashboard: true,
                      ),
                    );
                  } else if (swapCompleted != false) {
                    navigator.pop();
                  }
                },
        ),
      ],
    );
  }
}

class _PayQuoteMessage extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _PayQuoteMessage({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: RealUnitColors.neutral500),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              key: const ValueKey('payQuoteRetryButton'),
              onPressed: onRetry,
              child: Text(S.of(context).retry),
            ),
          ],
        ],
      ),
    );
  }
}
