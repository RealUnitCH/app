import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/legal/widgets/legal_document_button.dart';
import 'package:realunit_wallet/screens/legal/widgets/legal_step_styles.dart';
import 'package:realunit_wallet/screens/web_view/web_view_page.dart';

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
              style: LegalStepStyles.titleStyle,
            ),
            Text(
              s.aktionariatText,
              style: LegalStepStyles.bodyStyle,
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
              onTap: () => context.push(
                '/webView',
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
              onTap: () => context.push(
                '/webView',
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
              onTap: () => context.push(
                '/webView',
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
              onTap: () => context.push(
                '/webView',
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
