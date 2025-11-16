import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/styles/styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: PopScope(
          canPop: false,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/welcome_screen.png"),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.only(
                            left: 20, right: 20, top: 35, bottom: 35),
                        width: double.infinity,
                        child: Text(
                          S.of(context).your_deuro_cash_and_savings_wallet,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 20, bottom: 5, right: 20, left: 20),
                        child: InkWell(
                          onTap: () => launchUrl(
                            Uri.parse(
                                "https://docs.frankencoin.app/en/tou.html"),
                            mode: LaunchMode.externalApplication,
                          ),
                          enableFeedback: false,
                          child: Text.rich(
                            TextSpan(
                              text: S.of(context).welcome_disclaimer,
                              children: [
                                const TextSpan(text: "\n"),
                                TextSpan(
                                  text: S.of(context).terms_and_conditions,
                                  style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 20, bottom: 20, left: 10, right: 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: TextButton(
                                  onPressed: () =>
                                      context.go('/wallet/restore'),
                                  style: TextButton.styleFrom(
                                    fixedSize: Size(double.infinity, 55),
                                    backgroundColor: Colors.transparent,
                                  ),
                                  child: Text(
                                    S.of(context).import_wallet,
                                    style: kPrimaryButtonTextStyle,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 5),
                                child: TextButton(
                                  onPressed: () => context.go('/wallet/create'),
                                  style: kFullwidthPrimaryButtonStyle,
                                  child: Text(
                                    S.of(context).create_wallet,
                                    textAlign: TextAlign.center,
                                    style: kPrimaryButtonTextStyle,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  )),
            ),
          ),
        ),
      );
}
