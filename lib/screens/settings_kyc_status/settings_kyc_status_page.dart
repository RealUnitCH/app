import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';
import 'package:realunit_wallet/screens/kyc/kyc_page_manager.dart';
import 'package:realunit_wallet/screens/settings_kyc_status/cubit/settings_kyc_status_cubit.dart';
import 'package:realunit_wallet/setup/di.dart';
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
        title: Text(S.of(context).kycStatus),
      ),
      body: BlocBuilder<SettingsKycStatusCubit, SettingsKycStatusState>(
        builder: (context, state) {
          if (state is SettingsKycStatusSuccess) {
            final kycStatus = state.kycStatus;
            final level = kycStatus.level;
            final steps = kycStatus.steps;
            return Padding(
              padding: const .symmetric(horizontal: 20.0),
              child: LayoutBuilder(
                builder: (context, constraint) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraint.maxHeight),
                      child: IntrinsicHeight(
                        child: SafeArea(
                          child: Column(
                            spacing: 10,
                            children: [
                              Padding(
                                padding: const .all(24),
                                child: Text(
                                  S.of(context).kycLevelDescription('${level.value}'),
                                  textAlign: .center,
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                              ),
                              for (int i = 0; i < steps.length; i++)
                                Container(
                                  padding: const .all(20),
                                  decoration: BoxDecoration(
                                    color: RealUnitColors.neutral100,
                                    borderRadius: .circular(16),
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
                                      if (steps.elementAt(i).reason ==
                                          KycStepReason.accountMergeRequested) // edge case
                                        Text(S.of(context).kycStepStatusAccountMerge)
                                      else
                                        Text(steps.elementAt(i).status.localizedValue(context)),
                                    ],
                                  ),
                                ),
                              const Spacer(),
                              Row(
                                spacing: 12,
                                crossAxisAlignment: .start,
                                children: [
                                  const Icon(
                                    Icons.info,
                                    size: 24,
                                    color: RealUnitColors.realUnitBlue,
                                  ),
                                  Expanded(
                                    child: Column(
                                      spacing: 2.0,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          S.of(context).kycRequiredLevel,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.copyWith(fontWeight: .bold),
                                        ),
                                        Column(
                                          spacing: 4.0,
                                          crossAxisAlignment: .start,
                                          children: [
                                            Text(
                                              S
                                                  .of(context)
                                                  .kycRequiredStepsForBuy(KycStepName.ident.value),
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                            Text(
                                              S
                                                  .of(context)
                                                  .kycRequiredStepsForSell(
                                                    KycStepName.ident.value,
                                                  ),
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                            Text(
                                              S
                                                  .of(context)
                                                  .kycRequiredStepsWithHigherTradingLimit(
                                                    KycStepName.dfxApproval.value,
                                                  ),
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              if (kycStatus.canProceed)
                                Padding(
                                  padding: const .symmetric(vertical: 20),
                                  child: SizedBox(
                                    width: .infinity,
                                    child: FilledButton(
                                      onPressed: () async {
                                        await context.push(KycPageManager.routeName, extra: 50);
                                        if (context.mounted) {
                                          context.read<SettingsKycStatusCubit>().getKycStatus();
                                        }
                                      },
                                      child: Text(
                                        kycStatus.hasStarted
                                            ? S.of(context).next
                                            : S.of(context).start,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
