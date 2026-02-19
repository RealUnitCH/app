import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/kyc/kyc_page_manager.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/text_link_span.dart';

class LegalDisclaimerPage extends StatefulWidget {
  static const routeName = '/legalDisclaimer';

  const LegalDisclaimerPage({super.key});

  @override
  State<LegalDisclaimerPage> createState() => _LegalDisclaimerPageState();
}

class _LegalDisclaimerPageState extends State<LegalDisclaimerPage> {
  int _step = 0;
  bool _checkboxChecked = false;

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
                _checkboxChecked = false;
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
              Expanded(
                child: SingleChildScrollView(
                  key: ValueKey(_step),
                  child: _step < 2 ? _buildDisclaimerStep(s) : _buildCheckboxStep(s),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: _step < 2
                    ? Row(
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
                              onPressed: () => setState(() => _step++),
                              child: Text(s.legalDisclaimerYes),
                            ),
                          ),
                        ],
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _checkboxChecked
                              ? () async {
                                  final result = await context.push(KycPageManager.routeName);
                                  if (context.mounted) {
                                    context.pop(result);
                                  }
                                }
                              : null,
                          child: Text(s.next),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildCheckboxStep(S s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => setState(() => _checkboxChecked = !_checkboxChecked),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _checkboxChecked,
                  onChanged: (value) => setState(() => _checkboxChecked = value ?? false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      color: RealUnitColors.neutral600,
                    ),
                    children: [
                      TextSpan(text: '${s.legalDisclaimerCheckbox1} '),
                      TextLinkSpan.link(
                        context,
                        text: s.legalDisclaimerCheckboxPrivacyPolicy,
                        style: const TextStyle(
                          color: RealUnitColors.realUnitBlue,
                          decoration: TextDecoration.underline,
                        ),
                        uri: Uri.parse('https://realunit.ch/datenschutzerklaerung/'),
                      ),
                      TextSpan(text: ' ${s.legalDisclaimerCheckbox2} '),
                      TextLinkSpan.link(
                        context,
                        text: s.legalDisclaimerCheckboxRegistrationAgreement,
                        style: const TextStyle(
                          color: RealUnitColors.realUnitBlue,
                          decoration: TextDecoration.underline,
                        ),
                        uri: Uri.parse(
                          'https://realunit.de/ueber-uns/downloads/#registrierungsvereinbarung',
                        ),
                      ),
                      TextSpan(text: ' ${s.legalDisclaimerCheckbox3}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
