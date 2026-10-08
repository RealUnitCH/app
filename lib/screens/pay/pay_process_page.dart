import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/pay/swap_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_pay_service.dart';
import 'package:realunit_wallet/screens/pay/cubits/pay_process/pay_process_cubit.dart';
import 'package:realunit_wallet/screens/pay/widgets/pay_result_sheet.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/widgets/route_animation_gate.dart';

class PayProcessPage extends StatelessWidget {
  final String paymentLinkId;
  final String quoteId;
  final SwapPaymentInfo swap;

  const PayProcessPage({
    super.key,
    required this.paymentLinkId,
    required this.quoteId,
    required this.swap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PayProcessCubit(
        payService: getIt<RealUnitPayService>(),
        appStore: getIt<AppStore>(),
        paymentLinkId: paymentLinkId,
        quoteId: quoteId,
        swap: swap,
      ),
      child: RouteAnimationGate(
        onSettled: (c) => c.read<PayProcessCubit>().start(),
        child: const PayProcessView(),
      ),
    );
  }
}

class PayProcessView extends StatelessWidget {
  const PayProcessView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PayProcessCubit, PayProcessState>(
      listenWhen: (previous, current) =>
          current is PayProcessSuccess ||
          current is PayProcessFailure ||
          current is PayProcessPayRetry,
      listener: (context, state) async {
        if (state is PayProcessSuccess) {
          await _showResultSheet(
            context,
            icon: Icons.check_circle_rounded,
            title: S.of(context).paySuccess,
            description: S.of(context).paySuccessDescription,
            swapCompleted: true,
          );
        } else if (state is PayProcessPayRetry) {
          // The confirm may already have been sent. This payment leaves no CHF.
          // Retry sends the same delegation again.
          await _showRetrySheet(context, state);
        } else if (state is PayProcessFailure) {
          await _showResultSheet(
            context,
            icon: Icons.error_rounded,
            title: S.of(context).payFailureTitle,
            description: _failureMessage(context, state),
            swapCompleted: context.read<PayProcessCubit>().swapCompleted,
          );
        }
      },
      builder: (context, state) {
        final isTerminal =
            state is PayProcessSuccess ||
            state is PayProcessFailure ||
            state is PayProcessPayRetry;

        return Scaffold(
          appBar: AppBar(title: Text(S.of(context).pay)),
          body: SafeArea(
            child: Center(
              child: isTerminal
                  ? const SizedBox.shrink()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 24,
                      children: [
                        const CupertinoActivityIndicator(radius: 16),
                        Text(
                          _progressLabel(context, state),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  String _progressLabel(BuildContext context, PayProcessState state) => switch (state) {
    PayProcessInitial() || PayProcessPreparingSwap() => S.of(context).payPreparingSwap,
    PayProcessWaitingForEth() => S.of(context).payWaitingForEth,
    PayProcessSwapping() => S.of(context).paySwapping,
    PayProcessRefreshingQuote() => S.of(context).payRefreshingQuote,
    PayProcessPaying() => S.of(context).payPaying,
    PayProcessAwaitingSettlement() => S.of(context).payAwaitingSettlement,
    PayProcessSuccess() => S.of(context).paySuccess,
    PayProcessPayRetry() => S.of(context).payRetryTitle,
    PayProcessFailure() => S.of(context).payFailureTitle,
  };

  String _failureMessage(BuildContext context, PayProcessFailure state) {
    final apiText = state.message;
    if (apiText != null && apiText.isNotEmpty) {
      return apiText;
    }
    return switch (state.reason) {
      PayProcessFailureReason.insufficientEth => S.of(context).payFailureInsufficientEth,
      PayProcessFailureReason.signatureUnsupported => S.of(context).payFailureSignatureUnsupported,
      PayProcessFailureReason.payUnavailable => S.of(context).payFailurePayUnavailable,
      PayProcessFailureReason.bitboxRequired => S.of(context).payFailureBitboxRequired,
      PayProcessFailureReason.generic => S.of(context).payFailureGeneric,
    };
  }

  String _retryMessage(BuildContext context, PayProcessPayRetry state) {
    final apiText = state.message;
    if (apiText != null && apiText.isNotEmpty) {
      return apiText;
    }
    return switch (state.reason) {
      PayRetryReason.transient => S.of(context).payRetryTransient,
    };
  }

  Future<void> _showResultSheet(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required bool swapCompleted,
  }) async {
    await waitForIncomingRouteAnimation(context);
    if (!context.mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      builder: (sheetContext) => PayResultSheet(
        icon: icon,
        title: title,
        description: description,
        closeLabel: S.of(sheetContext).close,
        onClose: () => Navigator.of(sheetContext).pop(),
      ),
    );
    if (context.mounted) Navigator.of(context).pop(swapCompleted);
  }

  /// Recovery sheet when a pay confirm did not finish. This payment leaves no
  /// CHF in the wallet. The primary action ([PayProcessCubit.retryPay]) sends
  /// the same delegation again and can sell REALU if the first confirm did not
  /// arrive.
  Future<void> _showRetrySheet(
    BuildContext context,
    PayProcessPayRetry state,
  ) async {
    await waitForIncomingRouteAnimation(context);
    if (!context.mounted) {
      return;
    }

    final cubit = context.read<PayProcessCubit>();
    // The sheet returns true when the user retries (keep the page) and false
    // when they close (leave the flow); a barrier dismissal yields null.
    final retry = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      builder: (sheetContext) => PayResultSheet(
        icon: Icons.replay_rounded,
        title: S.of(sheetContext).payRetryTitle,
        description: _retryMessage(sheetContext, state),
        closeLabel: S.of(sheetContext).close,
        onClose: () => Navigator.of(sheetContext).pop(false),
        primaryLabel: S.of(sheetContext).payRetryButton,
        onPrimary: () => Navigator.of(sheetContext).pop(true),
      ),
    );

    if (retry == true) {
      // Send the same delegation again. Keep the page so the next attempt
      // surfaces its own result.
      await cubit.retryPay();
    } else if (context.mounted) {
      // Closed: leave the flow. This payment did not leave CHF in the wallet.
      // true tells the quote page not to offer Pay again on the same quote.
      Navigator.of(context).pop(true);
    }
  }
}
