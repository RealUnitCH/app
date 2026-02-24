import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/legal/cubit/legal_disclaimer_cubit.dart';
import 'package:realunit_wallet/screens/legal/steps/legal_aktionariat_step.dart';
import 'package:realunit_wallet/screens/legal/steps/legal_dfx_step.dart';
import 'package:realunit_wallet/screens/legal/steps/legal_disclaimer_step.dart';
import 'package:realunit_wallet/screens/legal/steps/legal_documents_step.dart';
import 'package:realunit_wallet/styles/colors.dart';

class LegalDisclaimerPage extends StatelessWidget {
  static const routeName = '/legalDisclaimer';

  const LegalDisclaimerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LegalDisclaimerCubit(),
      child: const _LegalDisclaimerView(),
    );
  }
}

class _LegalDisclaimerView extends StatelessWidget {
  const _LegalDisclaimerView();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return BlocBuilder<LegalDisclaimerCubit, LegalDisclaimerState>(
      builder: (context, state) {
        final cubit = context.read<LegalDisclaimerCubit>();
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () {
                if (state.canGoBack) {
                  cubit.previousStep();
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
                    value: state.progress,
                    backgroundColor: RealUnitColors.neutral200,
                    valueColor: const AlwaysStoppedAnimation<Color>(RealUnitColors.realUnitBlue),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: switch (state.currentStep) {
                        0 => LegalDisclaimerStep(step: state.currentStep),
                        1 => LegalDisclaimerStep(step: state.currentStep),
                        2 => const LegalDocumentsStep(),
                        3 => const LegalAktionariatStep(),
                        4 => const LegalDfxStep(),
                        _ => const SizedBox.shrink(),
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      spacing: 20.0,
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.pop(),
                            child: Text(s.legalDisclaimerNo),
                          ),
                        ),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => cubit.nextStep(
                              onComplete: () => context.pop(true),
                            ),
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
      },
    );
  }
}
