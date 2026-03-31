import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/config/legal_documents_config.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/outlined_tile.dart';

class LegalDfxStep extends StatelessWidget {
  const LegalDfxStep({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Column(
      crossAxisAlignment: .start,
      spacing: 20.0,
      children: [
        Column(
          crossAxisAlignment: .start,
          spacing: 16.0,
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
          ],
        ),

        Column(
          spacing: 12.0,
          children: [
            for (final document in DfxDocumentsConfig.allDocuments)
              OutlinedTile(
                leading: Icon(document.icon),
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
