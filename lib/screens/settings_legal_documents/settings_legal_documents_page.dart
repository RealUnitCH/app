import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/config/legal_documents_config.dart';
import 'package:realunit_wallet/setup/routing/routes/legal_routes.dart';
import 'package:realunit_wallet/widgets/outlined_tile.dart';

class SettingsLegalDocumentsPage extends StatelessWidget {
  const SettingsLegalDocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).legalDocuments),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const .symmetric(
            horizontal: 20.0,
            vertical: 12.0,
          ),
          child: Column(
            spacing: 12.0,
            children: [
              OutlinedTile(
                leadingIcon: Icons.description_outlined,
                title: S.of(context).termsOfUse,
                onTap: () => context.pushNamed(LegalRoutes.terms),
                trailingIcon: Icons.chevron_right_rounded,
              ),
              ...LegalDocumentsConfig.allDocuments.map(
                (config) => OutlinedTile(
                  leadingIcon: config.icon,
                  title: config.title(context),
                  onTap: () => config.onTap(context),
                  trailingIcon: Icons.chevron_right_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
