import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/referral/referral_error_message.dart';
import 'package:realunit_wallet/styles/colors.dart';

/// Bind-error overlay after `POST /v1/realunit/referral/bind` returns 4xx.
///
/// Title and body come from [localizedReferralErrorTitle] /
/// [localizedReferralError] so goldens and the live dashboard share one widget.
class ReferralBindErrorDialog extends StatelessWidget {
  final String token;

  const ReferralBindErrorDialog({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: RealUnitColors.status.red600,
    );
    return AlertDialog(
      title: Text(localizedReferralErrorTitle(context, token), style: style),
      content: Text(localizedReferralError(context, token), style: style),
      actions: [
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(S.of(context).close),
        ),
      ],
    );
  }
}
