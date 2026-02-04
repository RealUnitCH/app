import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/subpages/kyc_2fa_page.dart';
import 'package:realunit_wallet/screens/kyc/subpages/kyc_nationality_page.dart';
import 'package:realunit_wallet/screens/registration/registration_page.dart';

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
          return Scaffold(body: Center(child: CupertinoActivityIndicator()));
        }
        if (state is KycSuccess) {
          if (state.currentStep == KycStep.email) {
            return RegistrationPage();
          }
          if (state.currentStep == KycStep.nationality) {
            return KycNationalityPage(url: state.url!);
          }
          if (state.currentStep == KycStep.twoFa) {
            return Kyc2FaPage();
          }
          if (state.currentStep == KycStep.ident) {
            return Scaffold(appBar: AppBar(title: Text('Ident')));
          }

          if (state.currentStep == null) {
            return Scaffold(body: Center(child: Text('Finished 🥳')));
          }
        }
        return Scaffold();
      },
    );
  }
}
