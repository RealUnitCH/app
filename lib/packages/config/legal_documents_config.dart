import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/legal/subpages/legal_document_page.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/web_view/web_view_page.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/setup/routing/routes/legal_routes.dart';

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

  void onTap(BuildContext context) => context.pushNamed(
    LegalRoutes.document,
    extra: LegalDocumentParams(
      title: title(context),
      assetBaseName: assetBaseName,
      pdfUrls: pdfUrls,
    ),
  );
}

class LegalDocumentsConfig {
  static final allDocuments = [
    ...primaryDocuments,
    ...informationalDocuments,
  ];

  static final primaryDocuments = [
    _privacyPolicy,
    _registrationAgreement,
  ];

  static final informationalDocuments = [
    _euSecuritiesProspectusBearerShares,
    _euSecuritiesProspectusRegisteredShares,
    _chStockExchangeProspectus,
    _articlesOfAssociation,
    _investmentRegulations,
  ];

  static const _registrationAgreementPdfUrls = {
    'de':
        'https://realunit.ch/wp-content/uploads/2026/03/260303_RegV_DE_RealUnit_Schweiz_AG_signiert.pdf',
    'en':
        'https://realunit.ch/wp-content/uploads/2026/03/260303_RegV_EN_RealUnit_Schweiz_AG_signiert.pdf',
  };

  static const _euSecuritiesProspectusBearerSharesPdfUrls = {
    'de': 'https://realunit.de/ueber-uns/downloads/#eu_prospekte',
  };

  static const _euSecuritiesProspectusRegisteredSharesPdfUrls = {
    'de': 'https://realunit.de/ueber-uns/downloads/#eu_prospekte',
  };

  static const _chStockExchangeProspectusPDfUrls = {
    'de': 'https://realunit.ch/ueber-uns/downloads/#prospekt',
  };

  static const _articlesOfAssociationPdfUrls = {
    'de': 'https://realunit.ch/ueber-uns/downloads/#statuten',
  };

  static const _investmentRegulationsPdfUrls = {
    'de': 'https://realunit.ch/ueber-uns/downloads/#anlagereglement',
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

  static final _euSecuritiesProspectusBearerShares = LegalDocumentConfig(
    icon: Icons.article_outlined,
    title: (context) => S.of(context).legalDisclaimerCheckboxSecuritiesProspectusBearerShares,
    assetBaseName: 'securities_prospectus_bearer_shares',
    pdfUrls: _euSecuritiesProspectusBearerSharesPdfUrls,
  );

  static final _euSecuritiesProspectusRegisteredShares = LegalDocumentConfig(
    icon: Icons.article_outlined,
    title: (context) => S.of(context).legalDisclaimerCheckboxSecuritiesProspectusRegisteredShares,
    assetBaseName: 'securities_prospectus_registered_shares',
    pdfUrls: _euSecuritiesProspectusRegisteredSharesPdfUrls,
  );

  static final _chStockExchangeProspectus = LegalDocumentConfig(
    icon: Icons.article_outlined,
    title: (context) => S.of(context).legalDisclaimerCheckboxStockExchangeProspectus,
    assetBaseName: 'ch_stock_exchange_prospectus',
    pdfUrls: _chStockExchangeProspectusPDfUrls,
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

class WebDocumentConfig {
  final IconData icon;
  final String Function(BuildContext context) title;
  final String Function(BuildContext context) url;

  const WebDocumentConfig({
    required this.icon,
    required this.title,
    required this.url,
  });

  void onTap(BuildContext context) => context.pushNamed(
    AppRoutes.webView,
    extra: WebViewRouteParams(
      title: title(context),
      url: Uri.parse(url(context)),
    ),
  );
}

class AktionariatDocumentsConfig {
  static final allDocuments = [
    _termsOfService,
    _privacyPolicy,
    _disclaimer,
    _imprint,
  ];

  static final _termsOfService = WebDocumentConfig(
    icon: Icons.description_outlined,
    title: (context) => S.of(context).aktionariatTermsOfService,
    url: (_) => 'https://www.aktionariat.com/terms-of-service',
  );

  static final _privacyPolicy = WebDocumentConfig(
    icon: Icons.shield_outlined,
    title: (context) => S.of(context).aktionariatPrivacyPolicy,
    url: (_) => 'https://www.aktionariat.com/privacy-policy',
  );

  static final _disclaimer = WebDocumentConfig(
    icon: Icons.policy_outlined,
    title: (context) => S.of(context).aktionariatDisclaimer,
    url: (_) => 'https://www.aktionariat.com/disclaimer',
  );

  static final _imprint = WebDocumentConfig(
    icon: Icons.account_balance_outlined,
    title: (context) => S.of(context).aktionariatImprint,
    url: (_) => 'https://www.aktionariat.com/impressum',
  );
}

class DfxDocumentsConfig {
  static final allDocuments = [
    _termsAndConditions,
    _privacyPolicy,
    _disclaimer,
    _imprint,
  ];

  static final _termsAndConditions = WebDocumentConfig(
    icon: Icons.description_outlined,
    title: (context) => S.of(context).dfxTermsAndConditions,
    url: (context) {
      final language = context.read<SettingsBloc>().state.language.code;
      return 'https://docs.dfx.swiss/$language/tnc.html';
    },
  );

  static final _privacyPolicy = WebDocumentConfig(
    icon: Icons.shield_outlined,
    title: (context) => S.of(context).dfxPrivacyPolicy,
    url: (context) {
      final language = context.read<SettingsBloc>().state.language.code;
      return 'https://docs.dfx.swiss/$language/privacy.html';
    },
  );

  static final _disclaimer = WebDocumentConfig(
    icon: Icons.policy_outlined,
    title: (context) => S.of(context).dfxDisclaimer,
    url: (context) {
      final language = context.read<SettingsBloc>().state.language.code;
      return 'https://docs.dfx.swiss/$language/disclaimer.html';
    },
  );

  static final _imprint = WebDocumentConfig(
    icon: Icons.account_balance_outlined,
    title: (context) => S.of(context).dfxImprint,
    url: (context) {
      final language = context.read<SettingsBloc>().state.language.code;
      return 'https://docs.dfx.swiss/$language/imprint.html';
    },
  );
}
