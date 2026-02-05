import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/2fa/kyc_2fa_page.dart';
import 'package:realunit_wallet/screens/kyc/steps/ident/kyc_ident_page.dart';
import 'package:realunit_wallet/screens/kyc/steps/nationality/kyc_nationality_page.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/registration_page.dart';
import 'package:realunit_wallet/screens/kyc/subpages/kyc_level_reached_page.dart';
import 'package:realunit_wallet/screens/kyc/subpages/kyc_pending_page.dart';

class KycPage extends StatelessWidget {
  static const routeName = '/kyc';

  const KycPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => KycCubit(getIt<DfxKycService>())..checkKyc(),
      child: const KycView(),
    );
  }
}

class KycView extends StatelessWidget {
  const KycView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KycCubit, KycState>(
      builder: (context, state) {
        if (state is KycFailure) {
          return Scaffold(body: Center(child: Text('Failure: ${state.message}')));
        }
        if (state is KycLoading) {
          return const Scaffold(body: Center(child: CupertinoActivityIndicator()));
        }
        if (state is KycPending) {
          return KycPendingPage(pendingStep: state.pendingStep);
        }
        if (state is KycSuccess) {
          if (state.currentStep == KycStep.email) {
            return const RegistrationPage();
          }
          if (state.currentStep == KycStep.nationality) {
            return KycNationalityPage(url: state.url!);
          }
          if (state.currentStep == KycStep.twoFa) {
            return const Kyc2FaPage();
          }
          if (state.currentStep == KycStep.ident) {
            return KycIdentPage(accessToken: state.url!);
          }
          if (state.isCompleted) {
            return const KycLevelReachedPage();
          }
        }
        return const Scaffold();
      },
    );
  }
}
