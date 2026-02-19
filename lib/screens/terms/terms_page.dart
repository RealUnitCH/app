import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsPage extends StatelessWidget {
  static const route = '/terms';

  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/splash/splash_background.png',
            fit: BoxFit.cover,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00FFFFFF),
                    Color(0xFFFFFFFF),
                  ],
                ),
              ),
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 80,
                bottom: 40,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTermsText(s),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () =>
                            context.read<HomeBloc>().add(const AcceptSoftwareTermsEvent()),
                        child: Text(s.next),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsText(S s) => Text.rich(
    TextSpan(
      style: const TextStyle(
        fontSize: 14,
        height: 20 / 14,
        color: RealUnitColors.neutral600,
      ),
      children: [
        TextSpan(text: '${s.softwareTermsText} '),
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: () => _openUrl('https://realunit.ch/app/nutzungsbedingungen'),
            child: Text(
              s.termsAndConditions,
              style: const TextStyle(
                fontSize: 14,
                height: 20 / 14,
                color: RealUnitColors.realUnitBlue,
                decoration: TextDecoration.underline,
                decorationColor: RealUnitColors.realUnitBlue,
              ),
            ),
          ),
        ),
        TextSpan(text: ' ${s.terms2} '),
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: () => _openUrl('https://realunit.ch/app/haftungsausschluss'),
            child: Text(
              s.privacyPolicy,
              style: const TextStyle(
                fontSize: 14,
                height: 20 / 14,
                color: RealUnitColors.realUnitBlue,
                decoration: TextDecoration.underline,
                decorationColor: RealUnitColors.realUnitBlue,
              ),
            ),
          ),
        ),
        TextSpan(text: ' ${s.softwareTermsSuffix}.'),
      ],
    ),
    textAlign: TextAlign.center,
  );

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
