import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/config/legal_documents_config.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/outlined_tile.dart';

class LegalDocumentsStep extends StatelessWidget {
  const LegalDocumentsStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 24.0,
      children: [
        Column(
          crossAxisAlignment: .start,
          spacing: 12.0,
          children: [
            Text(
              S.of(context).legalDisclaimerDocumentsTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 18,
                height: 24 / 18,
              ),
            ),
            Text(
              S.of(context).legalDisclaimerDocumentsText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: RealUnitColors.neutral500,
              ),
            ),
            ...LegalDocumentsConfig.primaryDocuments.map(
              (config) => OutlinedTile(
                leading: Icon(config.icon, color: RealUnitColors.realUnitBlue, size: 24),
                title: config.title(context),
                onTap: () => config.onTap(context),
                trailingIcon: Icons.chevron_right_rounded,
              ),
            ),
          ],
        ),

        Column(
          crossAxisAlignment: .start,
          spacing: 12.0,
          children: [
            Text(
              '${S.of(context).legalDisclaimerAdditionalDocuments}:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: RealUnitColors.neutral500,
              ),
            ),
            ...LegalDocumentsConfig.informationalDocuments.map(
              (config) => OutlinedTile(
                leading: Icon(config.icon, color: RealUnitColors.realUnitBlue, size: 24),
                title: config.title(context),
                onTap: () => config.onTap(context),
                trailingIcon: Icons.chevron_right_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
