import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_pay_service.dart';
import 'package:realunit_wallet/screens/pay/cubits/pay_quote/pay_quote_cubit.dart';
import 'package:realunit_wallet/screens/pay/pay_process_page.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/styles/colors.dart';

class PayQuotePage extends StatelessWidget {
  final String paymentLinkId;

  const PayQuotePage({super.key, required this.paymentLinkId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PayQuoteCubit(getIt<RealUnitPayService>(), paymentLinkId)..load(),
      child: const PayQuoteView(),
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
              PayQuoteUnsupportedEnvironment() => _PayQuoteMessage(
                message: S.of(context).payFailureUnsupportedEnvironment,
              ),
              PayQuoteError() => _PayQuoteMessage(message: S.of(context).payFailureGeneric),
            },
          ),
        ),
      ),
    );
  }
}

class _PayQuoteReadyView extends StatelessWidget {
  final PayQuoteReady state;

  const _PayQuoteReadyView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 24,
      children: [
        const Spacer(),
        Text(
          S
              .of(context)
              .payQuoteSummary(
                state.fiatAmount.toStringAsFixed(2),
                state.fiatAsset,
              ),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        _AmountRow(
          label: S.of(context).payQuoteRequested,
          value: '${state.fiatAmount.toStringAsFixed(2)} ${state.fiatAsset}',
        ),
        _AmountRow(
          label: S.of(context).payQuoteZchfNeeded,
          value: '${state.zchfAmount.toStringAsFixed(2)} ZCHF',
        ),
        const Spacer(),
        FilledButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PayProcessPage(
                paymentLinkId: state.paymentLinkId,
                zchfNeeded: state.zchfAmount,
              ),
            ),
          ),
          child: Text(S.of(context).payConfirmButton),
        ),
      ],
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String value;

  const _AmountRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: RealUnitColors.neutral500,
          ),
        ),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

class _PayQuoteMessage extends StatelessWidget {
  final String message;

  const _PayQuoteMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: RealUnitColors.neutral500,
        ),
      ),
    );
  }
}
