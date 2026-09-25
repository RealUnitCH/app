import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_pay_service.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/screens/pay/cubits/pay_quote/pay_quote_cubit.dart';
import 'package:realunit_wallet/screens/pay/pay_process_page.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/styles/colors.dart';
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
              PayQuoteLoading() => const Center(child: CupertinoActivityIndicator()),
              PayQuoteReady() => _PayQuoteReadyView(state: state),
              PayQuoteExpired() => _PayQuoteMessage(message: S.of(context).payFailureQuoteExpired),
              PayQuoteUnavailable() => _PayQuoteMessage(message: S.of(context).payQuoteUnavailable),
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

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final swap = state.swap;
    final feeChf = swap.ethereumTransactionFeeChf;
    final feeRealu = swap.ethereumTransactionFeeRealu;
    // The customer pays the sold shares. The three lines split that total
    // into the bill, the fee, and the whole-share round-up. The signed
    // quote itself is not changed.
    final parts = _quoteParts(
      billChf: state.fiatAmount,
      shares: swap.amount,
      proceedsChf: swap.estimatedAmount,
      feeChf: feeChf ?? 0,
      feeRealu: feeRealu ?? 0,
    );
    final merchant = state.merchantName;
    return ScrollableActionsLayout(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (merchant != null) ...[
            Text(
              merchant,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (state.merchantCity != null)
              Text(
                state.merchantCity!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: RealUnitColors.neutral500,
                ),
              ),
            const SizedBox(height: 20),
          ],
          Text(
            S.of(context).payQuoteYouPay,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: RealUnitColors.neutral500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _wholeRealu(swap.amount),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 28),
          _ReceiptCard(
            children: [
              _AmountRow(
                label: S.of(context).payQuoteRequested,
                value: _chf(parts.billChf, state.fiatAsset),
                secondValue: _realu(parts.billRealu),
              ),
              _AmountRow(
                label: S.of(context).payQuoteRealuFees,
                value: _chf(parts.feeChf, 'CHF'),
                secondValue: _realu(parts.feeRealu),
              ),
              _AmountRow(
                label: S.of(context).payQuoteRounding,
                value: _chf(parts.roundingChf, 'CHF'),
                secondValue: _realu(parts.roundingRealu),
              ),
            ],
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
                  bool? swapCompleted = false;
                  try {
                    swapCompleted = await navigator.push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => PayProcessPage(
                          paymentLinkId: state.paymentLinkId,
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
                  if (mounted && swapCompleted != false) {
                    navigator.pop();
                  }
                },
        ),
      ],
    );
  }
}

String _chf(double amount, String asset) => '${amount.toStringAsFixed(2)} $asset';

String _wholeRealu(double shares) =>
    '${shares.toStringAsFixed(0)} ${realUnitAsset.symbol}';

/// At least two decimals, up to eight, without a tail of zeros.
String _realu(double amount) {
  final rounded = (amount * 1e8).round() / 1e8;
  var text = rounded.toStringAsFixed(8);
  text = text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  if (!text.contains('.')) {
    text = '$text.00';
  } else if (text.split('.').last.length == 1) {
    text = '${text}0';
  }
  return '$text ${realUnitAsset.symbol}';
}

class _QuoteParts {
  final double billChf;
  final double billRealu;
  final double feeChf;
  final double feeRealu;
  final double roundingChf;
  final double roundingRealu;

  const _QuoteParts({
    required this.billChf,
    required this.billRealu,
    required this.feeChf,
    required this.feeRealu,
    required this.roundingChf,
    required this.roundingRealu,
  });
}

/// Splits the sold shares into the bill, the fee, and the whole-share round-up.
/// The round-up is the remainder, so the three REALU lines add up to [shares].
_QuoteParts _quoteParts({
  required double billChf,
  required double shares,
  required double proceedsChf,
  required double feeChf,
  required double feeRealu,
}) {
  final price = shares == 0 ? 0.0 : proceedsChf / shares;
  final billRealu = price == 0 ? 0.0 : billChf / price;
  return _QuoteParts(
    billChf: billChf,
    billRealu: billRealu,
    feeChf: feeChf,
    feeRealu: feeRealu,
    roundingChf: proceedsChf - billChf - feeChf,
    roundingRealu: shares - billRealu - feeRealu,
  );
}

class _ReceiptCard extends StatelessWidget {
  final List<Widget> children;

  const _ReceiptCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) {
        rows.add(const Divider(height: 1, color: RealUnitColors.neutral200));
      }
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: RealUnitColors.neutral200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: rows),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String value;
  final String secondValue;

  const _AmountRow({
    required this.label,
    required this.value,
    required this.secondValue,
  });

  @override
  Widget build(BuildContext context) {
    final small = Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.3);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              label,
              softWrap: true,
              style: small?.copyWith(color: RealUnitColors.neutral500),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, textAlign: TextAlign.end, softWrap: true, style: small),
                Text(
                  secondValue,
                  textAlign: TextAlign.end,
                  softWrap: true,
                  style: small?.copyWith(color: RealUnitColors.neutral500),
                ),
              ],
            ),
          ),
        ],
      ),
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
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: RealUnitColors.neutral500,
            ),
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
