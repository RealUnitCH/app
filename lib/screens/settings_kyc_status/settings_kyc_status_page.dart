import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';
import 'package:realunit_wallet/screens/settings_kyc_status/cubit/settings_kyc_status_cubit.dart';
import 'package:realunit_wallet/styles/colors.dart';

class SettingsKycStatusPage extends StatelessWidget {
  const SettingsKycStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsKycStatusCubit(
        kycService: getIt<DfxKycService>(),
      )..getKycStatus(),
      child: const SettingsKycStatusView(),
    );
  }
}

class SettingsKycStatusView extends StatelessWidget {
  const SettingsKycStatusView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kyc Status'),
      ),
      body: BlocBuilder<SettingsKycStatusCubit, SettingsKycStatusState>(
        builder: (context, state) {
          if (state is SettingsKycStatusSuccess) {
            final level = state.dto.kycLevel;
            final steps = state.dto.kycSteps;
            return SingleChildScrollView(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    spacing: 10,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Dein KYC befindet sich auf Level ${level.value}.',
                          textAlign: .center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      for (int i = 0; i < steps.length; i++)
                        Container(
                          padding: const .all(20),
                          decoration: BoxDecoration(
                            color: RealUnitColors.neutral100,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            crossAxisAlignment: .start,
                            spacing: 20,
                            children: [
                              Text('$i.'),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: .start,
                                  children: [
                                    Text(
                                      steps.elementAt(i).name.value,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(fontWeight: .w600),
                                    ),
                                  ],
                                ),
                              ),
                              Text(steps.elementAt(i).status.value),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }
          if (state is SettingsKycStatusLoading) {
            return const Center(
              child: CupertinoActivityIndicator(),
            );
          }
          if (state is SettingsKycStatusFailure) {
            return Center(
              child: Text(state.message),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
