import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/styles/colors.dart';

class LegalDisclaimerStep extends StatelessWidget {
  final int step;

  const LegalDisclaimerStep({
    super.key,
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final title = step == 0 ? s.legalDisclaimerTitle : s.legalDisclaimerTitle2;
    final text = step == 0 ? s.legalDisclaimerText : s.legalDisclaimerText2;

    return Column(
      spacing: 16.0,
      crossAxisAlignment: .start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 18,
            height: 24 / 18,
          ),
        ),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: RealUnitColors.neutral500,
          ),
        ),
        if (step == 0)
          Text(
            s.legalDisclaimerAdvertising,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: RealUnitColors.neutral500,
            ),
          ),
      ],
    );
  }
}
