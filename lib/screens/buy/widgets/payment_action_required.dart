import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/styles/colors.dart';

class PaymentActionRequired extends StatelessWidget {
  final String title;
  final String description;
  final void Function()? onPressed;

  const PaymentActionRequired({
    super.key,
    required this.title,
    required this.description,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 20,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          spacing: 12,
          children: [
            Icon(
              Icons.info,
              size: 16,
              color: RealUnitColors.realUnitBlue,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).identity_check_required,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 18 / 14,
                    ),
                  ),
                  Text(
                    'Der Betrag liegt über Ihrem Limit. Um dieses zu erhöhen, bestätigen Sie bitte Ihre Identität (KYC) über DFX.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 18 / 14,
                      letterSpacing: 0.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (onPressed != null)
          FilledButton(
            onPressed: onPressed,
            child: Text(
              S.of(context).identity_confirm,
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
