import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/legal/widgets/legal_document_button.dart';
import 'package:realunit_wallet/screens/web_view/web_view_page.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/styles/colors.dart';

class LegalAktionariatStep extends StatelessWidget {
  const LegalAktionariatStep({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Column(
      spacing: 20.0,
      children: [
        Column(
          crossAxisAlignment: .start,
          spacing: 16.0,
          children: [
            Text(
              s.aktionariatTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 18,
                height: 24 / 18,
              ),
            ),
            Text(
              s.aktionariatText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: RealUnitColors.neutral500,
              ),
            ),
          ],
        ),
        Column(
          spacing: 12.0,
          children: [
            LegalDocumentButton(
              leadingIcon: Icons.description_outlined,
              trailingIcon: Icons.open_in_new_outlined,
              title: s.aktionariatTermsOfService,
              onTap: () => context.pushNamed(
                AppRoutes.webView,
                extra: WebViewRouteParams(
                  title: s.aktionariatTermsOfService,
                  url: Uri.parse('https://www.aktionariat.com/terms-of-service'),
                ),
              ),
            ),
            LegalDocumentButton(
              leadingIcon: Icons.shield_outlined,
              trailingIcon: Icons.open_in_new_outlined,
              title: s.aktionariatPrivacyPolicy,
              onTap: () => context.pushNamed(
                AppRoutes.webView,
                extra: WebViewRouteParams(
                  title: s.aktionariatPrivacyPolicy,
                  url: Uri.parse('https://www.aktionariat.com/privacy-policy'),
                ),
              ),
            ),
            LegalDocumentButton(
              leadingIcon: Icons.policy_outlined,
              trailingIcon: Icons.open_in_new_outlined,
              title: s.aktionariatDisclaimer,
              onTap: () => context.pushNamed(
                AppRoutes.webView,
                extra: WebViewRouteParams(
                  title: s.aktionariatDisclaimer,
                  url: Uri.parse('https://www.aktionariat.com/disclaimer'),
                ),
              ),
            ),
            LegalDocumentButton(
              leadingIcon: Icons.account_balance_outlined,
              trailingIcon: Icons.open_in_new_outlined,
              title: s.aktionariatImprint,
              onTap: () => context.pushNamed(
                AppRoutes.webView,
                extra: WebViewRouteParams(
                  title: s.aktionariatImprint,
                  url: Uri.parse('https://www.aktionariat.com/impressum'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
