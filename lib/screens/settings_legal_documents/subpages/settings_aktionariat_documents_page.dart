import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/legal/widgets/legal_document_button.dart';
import 'package:realunit_wallet/screens/web_view/web_view_page.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';

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
              LegalDocumentButton(
                leadingIcon: Icons.description_outlined,
                trailingIcon: Icons.open_in_new_outlined,
                title: S.of(context).aktionariatTermsOfService,
                onTap: () => context.pushNamed(
                  AppRoutes.webView,
                  extra: WebViewRouteParams(
                    title: S.of(context).aktionariatTermsOfService,
                    url: Uri.parse('https://www.aktionariat.com/terms-of-service'),
                  ),
                ),
              ),
              LegalDocumentButton(
                leadingIcon: Icons.shield_outlined,
                trailingIcon: Icons.open_in_new_outlined,
                title: S.of(context).aktionariatPrivacyPolicy,
                onTap: () => context.pushNamed(
                  AppRoutes.webView,
                  extra: WebViewRouteParams(
                    title: S.of(context).aktionariatPrivacyPolicy,
                    url: Uri.parse('https://www.aktionariat.com/privacy-policy'),
                  ),
                ),
              ),
              LegalDocumentButton(
                leadingIcon: Icons.policy_outlined,
                trailingIcon: Icons.open_in_new_outlined,
                title: S.of(context).aktionariatDisclaimer,
                onTap: () => context.pushNamed(
                  AppRoutes.webView,
                  extra: WebViewRouteParams(
                    title: S.of(context).aktionariatDisclaimer,
                    url: Uri.parse('https://www.aktionariat.com/disclaimer'),
                  ),
                ),
              ),
              LegalDocumentButton(
                leadingIcon: Icons.account_balance_outlined,
                trailingIcon: Icons.open_in_new_outlined,
                title: S.of(context).aktionariatImprint,
                onTap: () => context.pushNamed(
                  AppRoutes.webView,
                  extra: WebViewRouteParams(
                    title: S.of(context).aktionariatImprint,
                    url: Uri.parse('https://www.aktionariat.com/impressum'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
