import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_wallet_service.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/2fa/kyc_2fa_page.dart';
import 'package:realunit_wallet/screens/kyc/steps/financial_data/kyc_financial_data_page.dart';
import 'package:realunit_wallet/screens/kyc/steps/ident/kyc_ident_page.dart';
import 'package:realunit_wallet/screens/kyc/steps/nationality/kyc_nationality_page.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/kyc_registration_page.dart';
import 'package:realunit_wallet/screens/kyc/subpages/kyc_account_merge_page.dart';
import 'package:realunit_wallet/screens/kyc/subpages/kyc_completed_page.dart';
import 'package:realunit_wallet/screens/kyc/subpages/kyc_failure_page.dart';
import 'package:realunit_wallet/screens/kyc/subpages/kyc_loading_page.dart';
import 'package:realunit_wallet/screens/kyc/subpages/kyc_pending_page.dart';
import 'package:realunit_wallet/setup/di.dart';

class KycPageManager extends StatelessWidget {
  final int? requiredLevel;

  const KycPageManager({super.key, this.requiredLevel});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => KycCubit(
        getIt<DfxKycService>(),
        getIt<RealUnitWalletService>(),
        requiredLevel: requiredLevel,
      )..checkKyc(),
      child: const KycViewManager(),
    );
  }
}

class KycViewManager extends StatelessWidget {
  const KycViewManager({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KycCubit, KycState>(
      builder: (context, state) => switch (state) {
        KycLoading() => const KycLoadingPage(),
        KycFailure(:final message) => KycFailurePage(message: message),
        KycUnsupportedStepFailure(:final stepName) => KycFailurePage(
          message: S.of(context).kycUnsupportedStepDescription(stepName.value),
        ),
        KycAccountMergeRequested() => const KycAccountMergePage(),
        KycPending(:final pendingStep) => KycPendingPage(pendingStep: pendingStep),
        KycCompleted() => const KycCompletedPage(),
        KycSuccess(:final currentStep, :final urlOrToken, :final email) => switch (currentStep) {
          KycStep.registration => KycRegistrationPage(email: email),
          KycStep.nationality => KycNationalityPage(url: urlOrToken ?? ''),
          KycStep.twoFa => const Kyc2FaPage(),
          KycStep.ident => KycIdentPage(accessToken: urlOrToken ?? ''),
          KycStep.financialData => KycFinancialDataPage(url: urlOrToken ?? ''),
          (_) => const Scaffold(),
        },
        KycState() => const Scaffold(),
      },
    );
  }
}
