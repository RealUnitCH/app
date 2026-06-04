import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_transfer_service.dart';
import 'package:realunit_wallet/screens/send/cubits/send_process/send_process_cubit.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/styles/colors.dart';

/// Final step: prepare → sign (EIP-712 delegation + EIP-7702 authorization) →
/// confirm, then render the txHash success or a typed failure. The cubit drives
/// every outcome as a state — no error-string parsing in the view.
class SendProcessPage extends StatelessWidget {
  final String recipient;
  final int amount;

  const SendProcessPage({super.key, required this.recipient, required this.amount});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SendProcessCubit(
        transferService: getIt<RealUnitTransferService>(),
        appStore: getIt<AppStore>(),
        recipient: recipient,
        amount: amount,
      )..start(),
      child: const SendProcessView(),
    );
  }
}

class SendProcessView extends StatelessWidget {
  const SendProcessView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SendProcessCubit, SendProcessState>(
      listenWhen: (previous, current) =>
          current is SendProcessSuccess || current is SendProcessFailure,
      listener: (context, state) async {
        if (state is SendProcessSuccess) {
          await _showResultSheet(
            context,
            icon: Icons.check_circle_rounded,
            title: S.of(context).sendSuccess,
            description: S.of(context).sendSuccessDescription,
          );
        } else if (state is SendProcessFailure) {
          await _showResultSheet(
            context,
            icon: Icons.error_rounded,
            title: S.of(context).sendFailureTitle,
            description: _failureMessage(context, state.reason),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(S.of(context).sendProcessTitle)),
          body: SafeArea(
            child: Center(
              child: Column(
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

  String _progressLabel(BuildContext context, SendProcessState state) => switch (state) {
    SendProcessInitial() || SendProcessPreparing() => S.of(context).sendPreparing,
    SendProcessSigning() => S.of(context).sendSigning,
    SendProcessSuccess() => S.of(context).sendSuccess,
    SendProcessFailure() => S.of(context).sendFailureTitle,
  };

  String _failureMessage(BuildContext context, SendProcessFailureReason reason) => switch (reason) {
    SendProcessFailureReason.signatureUnsupported => S.of(context).sendFailureSignatureUnsupported,
    SendProcessFailureReason.signatureCancelled => S.of(context).sendFailureSignatureCancelled,
    SendProcessFailureReason.gasFundingUnavailable => S.of(context).sendFailureGasUnavailable,
    SendProcessFailureReason.invalidRequest => S.of(context).sendFailureInvalidRequest,
    SendProcessFailureReason.generic => S.of(context).sendFailureGeneric,
  };

  Future<void> _showResultSheet(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 24,
            children: [
              Icon(icon, color: RealUnitColors.realUnitBlue, size: 64),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: RealUnitColors.neutral500,
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(S.of(context).close),
              ),
            ],
          ),
        ),
      ),
    );
    if (context.mounted) Navigator.of(context).pop();
  }
}
