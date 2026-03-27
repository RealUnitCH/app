import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/config/legal_documents_config.dart';
import 'package:realunit_wallet/screens/legal/widgets/legal_document_button.dart';
import 'package:realunit_wallet/setup/routing/routes/legal_routes.dart';
import 'package:realunit_wallet/setup/routing/routes/settings_routes.dart';

class SettingsLegalDocumentsPage extends StatelessWidget {
  const SettingsLegalDocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.legalDocuments),
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
              LegalDocumentButton(
                leadingIcon: Icons.description_outlined,
                title: s.termsOfUse,
                onTap: () => context.pushNamed(LegalRoutes.terms),
              ),
              ...LegalDocumentsConfig.allDocuments.map(
                (config) => LegalDocumentButton(
                  leadingIcon: config.icon,
                  title: config.title(context),
                  onTap: () => config.onTap(context),
                ),
              ),
              LegalDocumentButton(
                leadingIcon: Icons.business_outlined,
                title: s.aktionariatTitle,
                onTap: () => context.pushNamed(SettingsRoutes.aktionariatDocuments),
              ),
              LegalDocumentButton(
                leadingIcon: Icons.business_outlined,
                title: s.dfxTitle,
                onTap: () => context.pushNamed(SettingsRoutes.dfxDocuments),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
