import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/financial_data/cubits/kyc_financial_data_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/financial_data/subpages/kyc_financial_data_failure_page.dart';
import 'package:realunit_wallet/screens/kyc/steps/financial_data/subpages/kyc_financial_data_loading_page.dart';
import 'package:realunit_wallet/screens/kyc/steps/financial_data/subpages/kyc_financial_data_questions_page.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/styles/colors.dart';

class KycFinancialDataPage extends StatelessWidget {
  final String url;

  const KycFinancialDataPage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          KycFinancialDataCubit(
            getIt<DfxKycService>(),
          )..loadQuestions(
            url,
            language: context.read<SettingsBloc>().state.language,
          ),
      child: const KycFinancialDataView(),
    );
  }
}

class KycFinancialDataView extends StatelessWidget {
  const KycFinancialDataView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<KycFinancialDataCubit, KycFinancialDataState>(
      listener: (context, state) {
        if (state is KycFinancialDataSubmitSuccess) {
          context.read<KycCubit>().checkKyc();
        }
        if (state is KycFinancialDataFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: RealUnitColors.status.red600,
            ),
          );
        }
      },
      child: BlocBuilder<KycFinancialDataCubit, KycFinancialDataState>(
        builder: (context, state) => switch (state) {
          KycFinancialDataLoading() ||
          KycFinancialDataSubmitting() => const KycFinancialDataLoadingPage(),
          KycFinancialDataLoadedSuccess() => KycFinancialDataQuestionsPage(state),
          KycFinancialDataFailure(:final message) => KycFinancialDataFailurePage(message: message),
          (_) => const Scaffold(),
        },
      ),
    );
  }
}
