import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/setup/routing/routes/legal_routes.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/text_substring_highlighting.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/splash/splash_background.png',
            fit: .cover,
          ),
          Align(
            alignment: .bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: .topCenter,
                  end: .bottomCenter,
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
                      padding: .only(
                        left: 20.0,
                        right: 20.0,
                        top: constraints.maxHeight * 0.2,
                      ),
                      child: Column(
                        mainAxisSize: .min,
                        children: [
                          TextSubstringHighlighting(
                            highlightedText: S.of(context).softwareTermsTextHighlighted,
                            highlightedStyle:
                                Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color: RealUnitColors.realUnitBlue,
                                  decorationColor: RealUnitColors.realUnitBlue,
                                  fontWeight: .bold,
                                  decoration: .underline,
                                ),
                            text: S.of(context).softwareTermsText,
                            style:
                                Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color: RealUnitColors.neutral500,
                                ),
                            textAlign: .center,
                            onHighlightedTap: () => context.pushNamed(LegalRoutes.terms),
                          ),
                          Padding(
                            padding: const .symmetric(vertical: 20.0),
                            child: AppFilledButton(
                              onPressed: () => context.read<HomeBloc>().add(
                                const AcceptSoftwareTermsEvent(),
                              ),
                              label: S.of(context).start,
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
