import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/text_link_span.dart';

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
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.4, 1.0],
                  colors: [
                    RealUnitColors.basic.white.withValues(alpha: 0),
                    RealUnitColors.basic.white,
                    RealUnitColors.basic.white,
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Padding(
                      padding: EdgeInsets.only(
                        left: 20.0,
                        right: 20.0,
                        top: constraints.maxHeight * 0.2,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 14,
                                height: 20 / 14,
                                color: RealUnitColors.neutral500,
                              ),
                              children: [
                                TextSpan(text: '${s.softwareTermsText} '),
                                TextLinkSpan.link(
                                  context,
                                  text: s.termsOfUse,
                                  style: const TextStyle(
                                    color: RealUnitColors.realUnitBlue,
                                    decoration: TextDecoration.underline,
                                  ),
                                  uri: Uri.parse('https://realunit.ch/app/nutzungsbedingungen'),
                                ),
                                TextSpan(text: ' ${s.softwareTermsSuffix}.'),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () =>
                                    context.read<HomeBloc>().add(const AcceptSoftwareTermsEvent()),
                                child: Text(s.next),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
