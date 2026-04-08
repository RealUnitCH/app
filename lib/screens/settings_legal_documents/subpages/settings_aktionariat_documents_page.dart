import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/config/legal_documents_config.dart';
import 'package:realunit_wallet/widgets/outlined_tile.dart';

class SettingsAktionariatDocumentsPage extends StatelessWidget {
  const SettingsAktionariatDocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).aktionariatTitle),
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
              for (final document in AktionariatDocumentsConfig.allDocuments)
                OutlinedTile(
                  leading: Icon(document.icon),
                  trailingIcon: Icons.open_in_new_outlined,
                  title: document.title(context),
                  onTap: () => document.onTap(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
