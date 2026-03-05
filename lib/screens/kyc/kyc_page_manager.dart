import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_wallet_service.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/2fa/kyc_2fa_page.dart';
import 'package:realunit_wallet/screens/kyc/steps/ident/kyc_ident_page.dart';
import 'package:realunit_wallet/screens/kyc/steps/nationality/kyc_nationality_page.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/kyc_registration_page.dart';
import 'package:realunit_wallet/screens/kyc/subpages/kyc_completed_page.dart';
import 'package:realunit_wallet/screens/kyc/subpages/kyc_failure_page.dart';
import 'package:realunit_wallet/screens/kyc/subpages/kyc_loading_page.dart';
import 'package:realunit_wallet/screens/kyc/subpages/kyc_pending_page.dart';

class KycPageManager extends StatelessWidget {
  static const routeName = '/kyc';

  const KycPageManager({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => KycCubit(
        getIt<DfxKycService>(),
        getIt<RealUnitWalletService>(),
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
        KycPending(:final pendingStep) => KycPendingPage(pendingStep: pendingStep),
        KycCompleted() => const KycCompletedPage(),
        KycSuccess(:final currentStep, :final urlOrToken) => switch (currentStep) {
          KycStep.registration => const KycRegistrationPage(),
          KycStep.nationality => KycNationalityPage(url: urlOrToken ?? ''),
          KycStep.twoFa => const Kyc2FaPage(),
          KycStep.ident => KycIdentPage(accessToken: urlOrToken ?? ''),
        },
        KycState() => const Scaffold(),
      },
    );
  }
}
