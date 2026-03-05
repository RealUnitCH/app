import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/legal/subpages/legal_document_page.dart';
import 'package:realunit_wallet/screens/legal/widgets/legal_document_button.dart';

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
          padding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 16.0,
          ),
          child: Column(
            spacing: 12.0,
            children: [
              LegalDocumentButton(
                leadingIcon: Icons.shield_outlined,
                title: S.of(context).legalDisclaimerCheckboxPrivacyPolicy,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LegalDocumentPage(
                      params: LegalDocumentParams(
                        title: S.of(context).legalDisclaimerCheckboxPrivacyPolicy,
                        assetBaseName: 'privacy_policy',
                      ),
                    ),
                  ),
                ),
              ),
              LegalDocumentButton(
                leadingIcon: Icons.description_outlined,
                title: S.of(context).legalDisclaimerCheckboxRegistrationAgreement,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LegalDocumentPage(
                      params: LegalDocumentParams(
                        title: S.of(context).legalDisclaimerCheckboxRegistrationAgreement,
                        assetBaseName: 'registration_agreement',
                        pdfUrls: const {
                          'de':
                              'https://realunit.de/wp-content/uploads/dlm_uploads/2025/03/250321_RegV-DE-RealUnit-Schweiz-AG_final_signed.pdf',
                          'en':
                              'https://realunit.de/wp-content/uploads/dlm_uploads/2025/03/250321_RegV-EN-RealUnit-Schweiz-AG_final_signed.pdf',
                        },
                      ),
                    ),
                  ),
                ),
              ),
              LegalDocumentButton(
                leadingIcon: Icons.article_outlined,
                title: S.of(context).legalDisclaimerCheckboxSecuritiesProspectusBearerShares,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LegalDocumentPage(
                      params: LegalDocumentParams(
                        title: S
                            .of(context)
                            .legalDisclaimerCheckboxSecuritiesProspectusBearerShares,
                        assetBaseName: 'securities_prospectus_bearer_shares',
                        pdfUrls: const {
                          'de':
                              'https://realunit.de/wp-content/uploads/dlm_uploads/2025/07/VO_RealUnit_Wertpapierprospekt_Inhaberaktie_30.06.2025_eIDAS-signiert.pdf',
                        },
                      ),
                    ),
                  ),
                ),
              ),
              LegalDocumentButton(
                leadingIcon: Icons.article_outlined,
                title: S.of(context).legalDisclaimerCheckboxSecuritiesProspectusRegisteredShares,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LegalDocumentPage(
                      params: LegalDocumentParams(
                        title: S
                            .of(context)
                            .legalDisclaimerCheckboxSecuritiesProspectusRegisteredShares,
                        assetBaseName: 'securities_prospectus_registered_shares',
                        pdfUrls: const {
                          'de':
                              'https://realunit.de/wp-content/uploads/dlm_uploads/2025/07/VO_RealUnit_Wertpapierprospekt_Namensaktien_30.06.2025_eIDAS-signiert.pdf',
                        },
                      ),
                    ),
                  ),
                ),
              ),
              LegalDocumentButton(
                leadingIcon: Icons.account_balance_outlined,
                title: S.of(context).legalDisclaimerCheckboxArticlesOfAssociation,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LegalDocumentPage(
                      params: LegalDocumentParams(
                        title: S.of(context).legalDisclaimerCheckboxArticlesOfAssociation,
                        assetBaseName: 'articles_of_association',
                        pdfUrls: const {
                          'de':
                              'https://realunit.de/wp-content/uploads/dlm_uploads/2025/06/250604-RUCH-Statuten-mit-Deckblatt.pdf',
                        },
                      ),
                    ),
                  ),
                ),
              ),
              LegalDocumentButton(
                leadingIcon: Icons.policy_outlined,
                title: S.of(context).legalDisclaimerCheckboxInvestmentRegulations,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LegalDocumentPage(
                      params: LegalDocumentParams(
                        title: S.of(context).legalDisclaimerCheckboxInvestmentRegulations,
                        assetBaseName: 'investment_regulations',
                        pdfUrls: const {
                          'de':
                              'https://realunit.de/wp-content/uploads/2025/03/250304_Anlagereglement_RealUnitSchweiz-AG.pdf',
                        },
                      ),
                    ),
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
