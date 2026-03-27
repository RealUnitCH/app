import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/legal/widgets/legal_document_button.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/web_view/web_view_page.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/styles/colors.dart';

class DfxDocumentsPage extends StatelessWidget {
  const DfxDocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final language = context.read<SettingsBloc>().state.language.code;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.dfxTitle),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const .symmetric(
            horizontal: 20.0,
            vertical: 12.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 20.0,
            children: [
              Text(
                s.dfxText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: RealUnitColors.neutral500,
                ),
              ),
              Column(
                spacing: 12.0,
                children: [
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
