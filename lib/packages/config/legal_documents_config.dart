import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/legal/subpages/legal_document_page.dart';

class LegalDocumentConfig {
  final IconData icon;
  final String Function(BuildContext context) title;
  final String assetBaseName;
  final Map<String, String>? pdfUrls;

  const LegalDocumentConfig({
    required this.icon,
    required this.title,
    required this.assetBaseName,
    this.pdfUrls,
  });

  void onTap(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => LegalDocumentPage(
        params: LegalDocumentParams(
          title: title(context),
          assetBaseName: assetBaseName,
          pdfUrls: pdfUrls,
        ),
      ),
    ),
  );
}

class LegalDocumentsConfig {
  static final allDocuments = [
    _privacyPolicy,
    _registrationAgreement,
    _securitiesProspectusBearerShares,
    _securitiesProspectusRegisteredShares,
    _articlesOfAssociation,
    _investmentRegulations,
  ];

  static const _registrationAgreementPdfUrls = {
    'de':
        'https://realunit.de/wp-content/uploads/dlm_uploads/2025/03/250321_RegV-DE-RealUnit-Schweiz-AG_final_signed.pdf',
    'en':
        'https://realunit.de/wp-content/uploads/dlm_uploads/2025/03/250321_RegV-EN-RealUnit-Schweiz-AG_final_signed.pdf',
  };

  static const _securitiesProspectusBearerSharesPdfUrls = {
    'de':
        'https://realunit.de/wp-content/uploads/dlm_uploads/2025/07/VO_RealUnit_Wertpapierprospekt_Inhaberaktie_30.06.2025_eIDAS-signiert.pdf',
  };

  static const _securitiesProspectusRegisteredSharesPdfUrls = {
    'de':
        'https://realunit.de/wp-content/uploads/dlm_uploads/2025/07/VO_RealUnit_Wertpapierprospekt_Namensaktien_30.06.2025_eIDAS-signiert.pdf',
  };

  static const _articlesOfAssociationPdfUrls = {
    'de':
        'https://realunit.de/wp-content/uploads/dlm_uploads/2025/06/250604-RUCH-Statuten-mit-Deckblatt.pdf',
  };

  static const _investmentRegulationsPdfUrls = {
    'de':
        'https://realunit.de/wp-content/uploads/2025/03/250304_Anlagereglement_RealUnitSchweiz-AG.pdf',
  };

  static final _privacyPolicy = LegalDocumentConfig(
    icon: Icons.shield_outlined,
    title: (context) => S.of(context).legalDisclaimerCheckboxPrivacyPolicy,
    assetBaseName: 'privacy_policy',
  );

  static final _registrationAgreement = LegalDocumentConfig(
    icon: Icons.description_outlined,
    title: (context) => S.of(context).legalDisclaimerCheckboxRegistrationAgreement,
    assetBaseName: 'registration_agreement',
    pdfUrls: _registrationAgreementPdfUrls,
  );

  static final _securitiesProspectusBearerShares = LegalDocumentConfig(
    icon: Icons.article_outlined,
    title: (context) => S.of(context).legalDisclaimerCheckboxSecuritiesProspectusBearerShares,
    assetBaseName: 'securities_prospectus_bearer_shares',
    pdfUrls: _securitiesProspectusBearerSharesPdfUrls,
  );

  static final _securitiesProspectusRegisteredShares = LegalDocumentConfig(
    icon: Icons.article_outlined,
    title: (context) => S.of(context).legalDisclaimerCheckboxSecuritiesProspectusRegisteredShares,
    assetBaseName: 'securities_prospectus_registered_shares',
    pdfUrls: _securitiesProspectusRegisteredSharesPdfUrls,
  );

  static final _articlesOfAssociation = LegalDocumentConfig(
    icon: Icons.account_balance_outlined,
    title: (context) => S.of(context).legalDisclaimerCheckboxArticlesOfAssociation,
    assetBaseName: 'articles_of_association',
    pdfUrls: _articlesOfAssociationPdfUrls,
  );

  static final _investmentRegulations = LegalDocumentConfig(
    icon: Icons.policy_outlined,
    title: (context) => S.of(context).legalDisclaimerCheckboxInvestmentRegulations,
    assetBaseName: 'investment_regulations',
    pdfUrls: _investmentRegulationsPdfUrls,
  );
}
