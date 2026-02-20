import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/legal/widgets/legal_step_styles.dart';

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: LegalStepStyles.titleStyle,
        ),
        Text(
          text,
          style: LegalStepStyles.bodyStyle,
        ),
      ],
    );
  }
}
