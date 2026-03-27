import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/config/legal_documents_config.dart';
import 'package:realunit_wallet/screens/legal/widgets/legal_document_button.dart';
import 'package:realunit_wallet/styles/colors.dart';

class LegalDfxStep extends StatelessWidget {
  const LegalDfxStep({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 20.0,
      children: [
        Text(
          s.dfxTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 18,
            height: 24 / 18,
          ),
        ),
        Text(
          s.dfxText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: RealUnitColors.neutral500,
          ),
        ),
        Column(
          spacing: 12.0,
          children: [
            for (final document in DfxDocumentsConfig.allDocuments)
              LegalDocumentButton(
                leadingIcon: document.icon,
                trailingIcon: Icons.open_in_new_outlined,
                title: document.title(context),
                onTap: () => document.onTap(context),
              ),
          ],
        ),
      ],
    );
  }
}
