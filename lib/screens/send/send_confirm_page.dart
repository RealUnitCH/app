import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/send/send_process_page.dart';
import 'package:realunit_wallet/styles/colors.dart';

/// Third step: review the recipient + amount before signing. Confirming starts
/// the on-chain process step.
class SendConfirmPage extends StatelessWidget {
  final String recipient;
  final int amount;

  const SendConfirmPage({super.key, required this.recipient, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).sendConfirmTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 24,
            children: [
              const Spacer(),
              Text(
                S.of(context).sendConfirmSummary(amount.toString()),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              _SummaryRow(
                label: S.of(context).sendConfirmAmount,
                value: S.of(context).sendShares(amount.toString()),
              ),
              _SummaryRow(
                label: S.of(context).sendConfirmRecipient,
                value: recipient,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SendProcessPage(recipient: recipient, amount: amount),
                  ),
                ),
                child: Text(S.of(context).sendConfirmButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: RealUnitColors.neutral500,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}
