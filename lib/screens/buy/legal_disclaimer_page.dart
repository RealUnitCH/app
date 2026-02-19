import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/kyc/kyc_page_manager.dart';
import 'package:realunit_wallet/screens/legal/legal_document_page.dart';
import 'package:realunit_wallet/styles/colors.dart';

class LegalDisclaimerPage extends StatefulWidget {
  static const routeName = '/legalDisclaimer';

  const LegalDisclaimerPage({super.key});

  @override
  State<LegalDisclaimerPage> createState() => _LegalDisclaimerPageState();
}

class _LegalDisclaimerPageState extends State<LegalDisclaimerPage> {
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (_step > 0) {
              setState(() {
                _step--;
              });
            } else {
              context.pop();
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(s.buyRealu),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: (_step + 1) / 6,
                backgroundColor: RealUnitColors.neutral200,
                valueColor: const AlwaysStoppedAnimation<Color>(RealUnitColors.realUnitBlue),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  key: ValueKey(_step),
                  child: _step < 2 ? _buildDisclaimerStep(s) : _buildDocumentsStep(s),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.pop(),
                        child: Text(s.legalDisclaimerNo),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          if (_step < 2) {
                            setState(() => _step++);
                          } else {
                            _navigateToKyc();
                          }
                        },
                        child: Text(s.legalDisclaimerYes),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToKyc() async {
    final navigator = GoRouter.of(context);
    final result = await navigator.push(KycPageManager.routeName);
    if (mounted && result != null) {
      navigator.pop(result);
    }
  }

  Widget _buildDisclaimerStep(S s) {
    final title = _step == 0 ? s.legalDisclaimerTitle : s.legalDisclaimerTitle2;
    final text = _step == 0 ? s.legalDisclaimerText : s.legalDisclaimerText2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            height: 24 / 18,
            color: RealUnitColors.neutral900,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            height: 20 / 14,
            color: RealUnitColors.neutral600,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDocumentsStep(S s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          s.legalDisclaimerDocumentsTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            height: 24 / 18,
            color: RealUnitColors.neutral900,
          ),
        ),
        const SizedBox(height: 24),
        _buildDocumentButton(
          icon: Icons.shield_outlined,
          title: s.legalDisclaimerCheckboxPrivacyPolicy,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LegalDocumentPage(
                params: LegalDocumentParams(
                  title: s.legalDisclaimerCheckboxPrivacyPolicy,
                  assetBaseName: 'privacy_policy',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildDocumentButton(
          icon: Icons.description_outlined,
          title: s.legalDisclaimerCheckboxRegistrationAgreement,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LegalDocumentPage(
                params: LegalDocumentParams(
                  title: s.legalDisclaimerCheckboxRegistrationAgreement,
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
        const SizedBox(height: 12),
        _buildDocumentButton(
          icon: Icons.article_outlined,
          title: s.legalDisclaimerCheckboxSecuritiesProspectusBearerShares,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LegalDocumentPage(
                params: LegalDocumentParams(
                  title: s.legalDisclaimerCheckboxSecuritiesProspectusBearerShares,
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
        const SizedBox(height: 12),
        _buildDocumentButton(
          icon: Icons.article_outlined,
          title: s.legalDisclaimerCheckboxSecuritiesProspectusRegisteredShares,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LegalDocumentPage(
                params: LegalDocumentParams(
                  title: s.legalDisclaimerCheckboxSecuritiesProspectusRegisteredShares,
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
        const SizedBox(height: 12),
        _buildDocumentButton(
          icon: Icons.account_balance_outlined,
          title: s.legalDisclaimerCheckboxArticlesOfAssociation,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LegalDocumentPage(
                params: LegalDocumentParams(
                  title: s.legalDisclaimerCheckboxArticlesOfAssociation,
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
        const SizedBox(height: 12),
        _buildDocumentButton(
          icon: Icons.policy_outlined,
          title: s.legalDisclaimerCheckboxInvestmentRegulations,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LegalDocumentPage(
                params: LegalDocumentParams(
                  title: s.legalDisclaimerCheckboxInvestmentRegulations,
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
    );
  }

  Widget _buildDocumentButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: RealUnitColors.neutral200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: RealUnitColors.realUnitBlue, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 22 / 16,
                    fontWeight: FontWeight.w500,
                    color: RealUnitColors.neutral900,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: RealUnitColors.neutral400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
