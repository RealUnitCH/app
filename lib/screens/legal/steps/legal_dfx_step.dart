import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/legal/widgets/legal_document_button.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/web_view/web_view_page.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/styles/colors.dart';

class LegalDfxStep extends StatelessWidget {
  const LegalDfxStep({super.key});

  @override
  Widget build(BuildContext context) {
    final language = context.read<SettingsBloc>().state.language.code;
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
            LegalDocumentButton(
              leadingIcon: Icons.description_outlined,
              trailingIcon: Icons.open_in_new_outlined,
              title: s.dfxTermsAndConditions,
              onTap: () => context.pushNamed(
                AppRoutes.webView,
                extra: WebViewRouteParams(
                  title: s.dfxTermsAndConditions,
                  url: Uri.parse('https://docs.dfx.swiss/$language/tnc.html'),
                ),
              ),
            ),
            LegalDocumentButton(
              leadingIcon: Icons.shield_outlined,
              trailingIcon: Icons.open_in_new_outlined,
              title: s.dfxPrivacyPolicy,
              onTap: () => context.pushNamed(
                AppRoutes.webView,
                extra: WebViewRouteParams(
                  title: s.dfxPrivacyPolicy,
                  url: Uri.parse('https://docs.dfx.swiss/$language/privacy.html'),
                ),
              ),
            ),
            LegalDocumentButton(
              leadingIcon: Icons.policy_outlined,
              trailingIcon: Icons.open_in_new_outlined,
              title: s.dfxDisclaimer,
              onTap: () => context.pushNamed(
                AppRoutes.webView,
                extra: WebViewRouteParams(
                  title: s.dfxDisclaimer,
                  url: Uri.parse('https://docs.dfx.swiss/$language/disclaimer.html'),
                ),
              ),
            ),
            LegalDocumentButton(
              leadingIcon: Icons.account_balance_outlined,
              trailingIcon: Icons.open_in_new_outlined,
              title: s.dfxImprint,
              onTap: () => context.pushNamed(
                AppRoutes.webView,
                extra: WebViewRouteParams(
                  title: s.dfxImprint,
                  url: Uri.parse('https://docs.dfx.swiss/$language/imprint.html'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
