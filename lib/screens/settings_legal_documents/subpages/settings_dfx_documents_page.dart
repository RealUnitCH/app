import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/legal/widgets/legal_document_button.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/web_view/web_view_page.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';

class SettingsDfxDocumentsPage extends StatelessWidget {
  const SettingsDfxDocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final language = context.read<SettingsBloc>().state.language.code;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).dfxTitle),
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
                title: S.of(context).dfxTermsAndConditions,
                onTap: () => context.pushNamed(
                  AppRoutes.webView,
                  extra: WebViewRouteParams(
                    title: S.of(context).dfxTermsAndConditions,
                    url: Uri.parse('https://docs.dfx.swiss/$language/tnc.html'),
                  ),
                ),
              ),
              LegalDocumentButton(
                leadingIcon: Icons.shield_outlined,
                trailingIcon: Icons.open_in_new_outlined,
                title: S.of(context).dfxPrivacyPolicy,
                onTap: () => context.pushNamed(
                  AppRoutes.webView,
                  extra: WebViewRouteParams(
                    title: S.of(context).dfxPrivacyPolicy,
                    url: Uri.parse('https://docs.dfx.swiss/$language/privacy.html'),
                  ),
                ),
              ),
              LegalDocumentButton(
                leadingIcon: Icons.policy_outlined,
                trailingIcon: Icons.open_in_new_outlined,
                title: S.of(context).dfxDisclaimer,
                onTap: () => context.pushNamed(
                  AppRoutes.webView,
                  extra: WebViewRouteParams(
                    title: S.of(context).dfxDisclaimer,
                    url: Uri.parse('https://docs.dfx.swiss/$language/disclaimer.html'),
                  ),
                ),
              ),
              LegalDocumentButton(
                leadingIcon: Icons.account_balance_outlined,
                trailingIcon: Icons.open_in_new_outlined,
                title: S.of(context).dfxImprint,
                onTap: () => context.pushNamed(
                  AppRoutes.webView,
                  extra: WebViewRouteParams(
                    title: S.of(context).dfxImprint,
                    url: Uri.parse('https://docs.dfx.swiss/$language/imprint.html'),
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
