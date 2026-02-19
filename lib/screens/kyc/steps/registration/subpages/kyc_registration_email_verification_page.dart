import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_widget_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/cubits/registration_email_verification/kyc_registration_email_verification_cubit.dart';
import 'package:realunit_wallet/styles/colors.dart';

class KycRegistrationEmailVerificationPage extends StatelessWidget {
  const KycRegistrationEmailVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => KycRegistrationEmailVerificationCubit(
        dfxService: getIt<DfxWidgetService>(),
        registrationService: getIt<RealUnitRegistrationService>(),
      ),
      child: const KycRegistrationEmailVerificationStepView(),
    );
  }
}

class KycRegistrationEmailVerificationStepView extends StatelessWidget {
  const KycRegistrationEmailVerificationStepView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<
      KycRegistrationEmailVerificationCubit,
      KycRegistrationEmailVerificationState
    >(
      listener: (context, state) {
        if (state is KycRegistrationEmailVerificationFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).registerEmailVerificationFailed),
              backgroundColor: RealUnitColors.status.red600,
            ),
          );
        }
        if (state is KycRegistrationEmailVerificationRegistrationFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Der Account Merge war erfolgreich, jedoch konnte die Wallet nicht registriert werden. Bitte melden Sie sich beim Support',
              ),
              backgroundColor: RealUnitColors.status.red600,
            ),
          );
        }
        if (state is KycRegistrationEmailVerificationSuccess) {
          context.pop(true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).registerEmailVerification),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SafeArea(
            child: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: Column(
                children: [
                  const SizedBox(height: 44.0),
                  SvgPicture.asset('assets/images/illustrations/email_verification.svg', width: 75),
                  const SizedBox(height: 20.0),
                  Column(
                    spacing: 8.0,
                    children: [
                      Text(
                        S.of(context).registerEmailVerificationTitle,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          height: 30 / 26,
                          letterSpacing: -0.52,
                        ),
                      ),
                      Text(
                        S.of(context).registerEmailVerificationDescription,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 18 / 14,
                          color: RealUnitColors.neutral500,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child:
                              BlocBuilder<
                                KycRegistrationEmailVerificationCubit,
                                KycRegistrationEmailVerificationState
                              >(
                                builder: (context, state) {
                                  if (state is KycRegistrationEmailVerificationLoading) {
                                    return FilledButton.icon(
                                      onPressed: null,
                                      icon: SizedBox(
                                        height: 14,
                                        width: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: RealUnitColors.basic.black.withValues(alpha: 0.5),
                                        ),
                                      ),
                                      label: Text(
                                        S.of(context).registerEmailVerificationButton,
                                      ),
                                    );
                                  }
                                  return FilledButton(
                                    onPressed: () => context
                                        .read<KycRegistrationEmailVerificationCubit>()
                                        .checkEmailVerification(),
                                    child: Text(
                                      S.of(context).registerEmailVerificationButton,
                                    ),
                                  );
                                },
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
