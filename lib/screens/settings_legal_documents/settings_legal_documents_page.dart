import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/config/legal_documents_config.dart';
import 'package:realunit_wallet/screens/legal/widgets/legal_document_button.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/web_view/web_view_page.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/setup/routing/routes/legal_routes.dart';
import 'package:realunit_wallet/styles/colors.dart';

class SettingsLegalDocumentsPage extends StatelessWidget {
  const SettingsLegalDocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final language = context.read<SettingsBloc>().state.language.code;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.legalDocuments),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 12.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // RealUnit Section
              _SectionHeader(title: s.realunitTitle),
              const SizedBox(height: 12.0),
              LegalDocumentButton(
                leadingIcon: Icons.description_outlined,
                title: s.termsOfUse,
                onTap: () => context.pushNamed(LegalRoutes.terms),
              ),
              const SizedBox(height: 12.0),
              ...LegalDocumentsConfig.allDocuments.map(
                (config) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: LegalDocumentButton(
                    leadingIcon: config.icon,
                    title: config.title(context),
                    onTap: () => config.onTap(context),
                  ),
                ),
              ),

              const SizedBox(height: 24.0),

              // Aktionariat Section
              _SectionHeader(title: s.aktionariatTitle),
              const SizedBox(height: 12.0),
              LegalDocumentButton(
                leadingIcon: Icons.description_outlined,
                trailingIcon: Icons.open_in_new_outlined,
                title: s.aktionariatTermsOfService,
                onTap: () => _openWebView(
                  context,
                  s.aktionariatTermsOfService,
                  'https://www.aktionariat.com/terms-of-service',
                ),
              ),
              const SizedBox(height: 12.0),
              LegalDocumentButton(
                leadingIcon: Icons.shield_outlined,
                trailingIcon: Icons.open_in_new_outlined,
                title: s.aktionariatPrivacyPolicy,
                onTap: () => _openWebView(
                  context,
                  s.aktionariatPrivacyPolicy,
                  'https://www.aktionariat.com/privacy-policy',
                ),
              ),
              const SizedBox(height: 12.0),
              LegalDocumentButton(
                leadingIcon: Icons.policy_outlined,
                trailingIcon: Icons.open_in_new_outlined,
                title: s.aktionariatDisclaimer,
                onTap: () => _openWebView(
                  context,
                  s.aktionariatDisclaimer,
                  'https://www.aktionariat.com/disclaimer',
                ),
              ),
              const SizedBox(height: 12.0),
              LegalDocumentButton(
                leadingIcon: Icons.account_balance_outlined,
                trailingIcon: Icons.open_in_new_outlined,
                title: s.aktionariatImprint,
                onTap: () => _openWebView(
                  context,
                  s.aktionariatImprint,
                  'https://www.aktionariat.com/impressum',
                ),
              ),

              const SizedBox(height: 24.0),

              // DFX Section
              _SectionHeader(title: s.dfxTitle),
              const SizedBox(height: 12.0),
              LegalDocumentButton(
                leadingIcon: Icons.description_outlined,
                trailingIcon: Icons.open_in_new_outlined,
                title: s.dfxTermsAndConditions,
                onTap: () => _openWebView(
                  context,
                  s.dfxTermsAndConditions,
                  'https://docs.dfx.swiss/$language/tnc.html',
                ),
              ),
              const SizedBox(height: 12.0),
              LegalDocumentButton(
                leadingIcon: Icons.shield_outlined,
                trailingIcon: Icons.open_in_new_outlined,
                title: s.dfxPrivacyPolicy,
                onTap: () => _openWebView(
                  context,
                  s.dfxPrivacyPolicy,
                  'https://docs.dfx.swiss/$language/privacy.html',
                ),
              ),
              const SizedBox(height: 12.0),
              LegalDocumentButton(
                leadingIcon: Icons.policy_outlined,
                trailingIcon: Icons.open_in_new_outlined,
                title: s.dfxDisclaimer,
                onTap: () => _openWebView(
                  context,
                  s.dfxDisclaimer,
                  'https://docs.dfx.swiss/$language/disclaimer.html',
                ),
              ),
              const SizedBox(height: 12.0),
              LegalDocumentButton(
                leadingIcon: Icons.account_balance_outlined,
                trailingIcon: Icons.open_in_new_outlined,
                title: s.dfxImprint,
                onTap: () => _openWebView(
                  context,
                  s.dfxImprint,
                  'https://docs.dfx.swiss/$language/imprint.html',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openWebView(BuildContext context, String title, String url) {
    context.pushNamed(
      AppRoutes.webView,
      extra: WebViewRouteParams(
        title: title,
        url: Uri.parse(url),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: RealUnitColors.neutral500,
          ),
    );
  }
}
