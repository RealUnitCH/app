import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/styles.dart';
import 'package:realunit_wallet/widgets/text_link_span.dart';

class OnboardingCompletedPage extends StatefulWidget {
  static const route = '/onboardingComplete';

  const OnboardingCompletedPage({super.key});

  @override
  State<OnboardingCompletedPage> createState() => _OnboardingCompletedPageState();
}

class _OnboardingCompletedPageState extends State<OnboardingCompletedPage> {
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      backgroundColor: RealUnitColors.brand700,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: RealUnitColors.realUnitBlack,
            size: 24,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              Image.asset(
                "assets/images/realu_tokens.png",
                height: 300,
              ),
              const SizedBox(height: 40.0),
              Column(
                spacing: 8.0,
                children: [
                  Text(
                    s.onboarding_completed_title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                      letterSpacing: 26 * -0.02,
                      height: 30 / 26,
                    ),
                  ),
                  Text(
                    s.onboarding_completed_subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 18 / 14,
                      letterSpacing: 0.0,
                      color: RealUnitColors.neutral500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                spacing: 12,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      checkColor: Colors.white,
                      activeColor: RealUnitColors.green,
                      value: isChecked,
                      onChanged: (value) => setState(() => isChecked = value ?? false),
                    ),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                          height: 16 / 12,
                        ),
                        children: [
                          TextSpan(text: '${s.terms_1} '),
                          TextLinkSpan.link(context,
                              text: s.realunit_ag, uri: Uri.parse('https://google.com')),
                          TextSpan(text: ' ${s.terms_2} '),
                          TextLinkSpan.link(context,
                              text: s.dfx_ag, uri: Uri.parse('https://google.com')),
                          TextSpan(text: ' ${s.terms_3} '),
                          TextLinkSpan.link(context,
                              text: s.terms_agreement, uri: Uri.parse('https://google.com')),
                          TextSpan(text: ' ${s.terms_4} ${s.realunit_ag} ${s.terms_5}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: isChecked
                        ? () => context.read<HomeBloc>().add((CompleteOnboardingEvent()))
                        : null,
                    style: kFullwidthBlueButtonStyle.copyWith(
                      backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                        (states) => states.contains(WidgetState.disabled)
                            ? RealUnitColors.neutral200
                            : RealUnitColors.realUnitBlue,
                      ),
                      foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                        (states) => states.contains(WidgetState.disabled)
                            ? RealUnitColors.neutral400
                            : Colors.white,
                      ),
                    ),
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
}
