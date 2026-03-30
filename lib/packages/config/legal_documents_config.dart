import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/legal/subpages/legal_document_page.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/web_view/web_view_page.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/setup/routing/routes/legal_routes.dart';
import 'package:url_launcher/url_launcher.dart';

abstract class DocumentConfig {
  IconData get icon;
  bool get isExternal;
  String title(BuildContext context);
  void onTap(BuildContext context);
}

class LegalDocumentConfig implements DocumentConfig {
  @override
  final IconData icon;
  @override
  bool get isExternal => false;
  final String Function(BuildContext context) _title;
  final String assetBaseName;
  final Map<String, String>? pdfUrls;

  const LegalDocumentConfig({
    required this.icon,
    required String Function(BuildContext context) title,
    required this.assetBaseName,
    this.pdfUrls,
  }) : _title = title;

  @override
  String title(BuildContext context) => _title(context);

  @override
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
  static final List<DocumentConfig> allDocuments = [
    ...primaryDocuments,
    ...informationalDocuments,
  ];

  static final List<DocumentConfig> primaryDocuments = [
    _privacyPolicy,
    _registrationAgreement,
  ];

  static final List<DocumentConfig> informationalDocuments = [
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

  static final _euSecuritiesProspectusBearerShares = WebDocumentConfig(
    icon: Icons.article_outlined,
    title: (context) => S.of(context).legalDisclaimerCheckboxSecuritiesProspectusBearerShares,
    url: (_) => 'https://realunit.de/ueber-uns/downloads/#eu_prospekte',
    openExternally: true,
  );

  static final _euSecuritiesProspectusRegisteredShares = WebDocumentConfig(
    icon: Icons.article_outlined,
    title: (context) => S.of(context).legalDisclaimerCheckboxSecuritiesProspectusRegisteredShares,
    url: (_) => 'https://realunit.de/ueber-uns/downloads/#eu_prospekte',
    openExternally: true,
  );

  static final _chStockExchangeProspectus = WebDocumentConfig(
    icon: Icons.article_outlined,
    title: (context) => S.of(context).legalDisclaimerCheckboxStockExchangeProspectus,
    url: (_) => 'https://realunit.ch/ueber-uns/downloads/#prospekt',
    openExternally: true,
  );

  static final _articlesOfAssociation = WebDocumentConfig(
    icon: Icons.account_balance_outlined,
    title: (context) => S.of(context).legalDisclaimerCheckboxArticlesOfAssociation,
    url: (_) => 'https://realunit.ch/ueber-uns/downloads/#statuten',
    openExternally: true,
  );

  static final _investmentRegulations = WebDocumentConfig(
    icon: Icons.policy_outlined,
    title: (context) => S.of(context).legalDisclaimerCheckboxInvestmentRegulations,
    url: (_) => 'https://realunit.ch/ueber-uns/downloads/#anlagereglement',
    openExternally: true,
  );
}

class WebDocumentConfig implements DocumentConfig {
  @override
  final IconData icon;
  @override
  bool get isExternal => openExternally;
  final String Function(BuildContext context) _title;
  final String Function(BuildContext context) url;
  final bool openExternally;

  const WebDocumentConfig({
    required this.icon,
    required String Function(BuildContext context) title,
    required this.url,
    this.openExternally = false,
  }) : _title = title;

  @override
  String title(BuildContext context) => _title(context);

  @override
  void onTap(BuildContext context) {
    if (openExternally) {
      launchUrl(Uri.parse(url(context)), mode: LaunchMode.externalApplication);
    } else {
      context.pushNamed(
        AppRoutes.webView,
        extra: WebViewRouteParams(
          title: title(context),
          url: Uri.parse(url(context)),
        ),
      );
    }
  }
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
