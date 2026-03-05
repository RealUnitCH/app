import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/config/legal_documents_config.dart';
import 'package:realunit_wallet/screens/legal/widgets/legal_document_button.dart';
import 'package:realunit_wallet/screens/legal/widgets/legal_step_styles.dart';

class LegalDocumentsStep extends StatelessWidget {
  const LegalDocumentsStep({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Column(
      spacing: 20.0,
      children: [
        Column(
          crossAxisAlignment: .start,
          spacing: 16.0,
          children: [
            Text(
              s.legalDisclaimerDocumentsTitle,
              style: LegalStepStyles.titleStyle,
            ),
            Text(
              s.legalDisclaimerDocumentsText,
              style: LegalStepStyles.bodyStyle,
            ),
          ],
        ),
        Column(
          spacing: 12.0,
          children: LegalDocumentsConfig.allDocuments
              .map(
                (config) => LegalDocumentButton(
                  leadingIcon: config.icon,
                  title: config.title(context),
                  onTap: () => config.onTap(context),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
