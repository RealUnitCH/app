import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/styles/colors.dart';

class OnboardingCompletedPage extends StatelessWidget {
  static const route = '/onboardingComplete';

  const OnboardingCompletedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      backgroundColor: RealUnitColors.brand700,
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: LayoutBuilder(
            builder: (context, constraint) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraint.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/realu_tokens.png',
                          height: 280,
                        ),
                        const SizedBox(height: 40.0),
                        Column(
                          spacing: 8.0,
                          children: [
                            Text(
                              s.onboardingCompletedTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 26,
                                letterSpacing: 26 * -0.02,
                                height: 30 / 26,
                              ),
                            ),
                            Text(
                              s.onboardingCompletedSubtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 18 / 14,
                                letterSpacing: 0.0,
                                color: RealUnitColors.neutral500,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () =>
                                  context.read<HomeBloc>().add(const CompleteOnboardingEvent()),
                              child: Text(s.next),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
