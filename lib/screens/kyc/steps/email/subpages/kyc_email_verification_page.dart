import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_credentials.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_widget_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_wallet_service.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/kyc/steps/email/cubits/email_verification/kyc_email_verification_cubit.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

class KycEmailVerificationPage extends StatelessWidget {
  const KycEmailVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => KycEmailVerificationCubit(
        dfxService: getIt<DfxWidgetService>(),
        walletService: getIt<RealUnitWalletService>(),
        registrationService: getIt<RealUnitRegistrationService>(),
      ),
      child: const KycEmailVerificationView(),
    );
  }
}

class KycEmailVerificationView extends StatelessWidget {
  const KycEmailVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<KycEmailVerificationCubit, KycEmailVerificationState>(
      listener: (context, state) {
        if (state is KycEmailVerificationFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).registerEmailVerificationFailed),
              backgroundColor: RealUnitColors.status.red600,
            ),
          );
        }
        if (state is KycEmailVerificationRegistrationFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                S.of(context).registerEmailVerificationRegistrationFailed,
              ),
              backgroundColor: RealUnitColors.status.red600,
            ),
          );
        }
        if (state is KycEmailVerificationSuccess) {
          context.pop(true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).registerEmailVerification),
        ),
        body: SingleChildScrollView(
          padding: const .symmetric(horizontal: 20),
          child: SafeArea(
            child: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: Column(
                children: [
                  const SizedBox(height: 44.0),
                  SvgPicture.asset(
                    'assets/images/illustrations/email_verification.svg',
                    width: 75,
                  ),
                  const SizedBox(height: 20.0),
                  Column(
                    spacing: 8.0,
                    children: [
                      Text(
                        S.of(context).registerEmailVerificationTitle,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        S.of(context).registerEmailVerificationDescription,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: RealUnitColors.neutral500,
                        ),
                      ),
                      Padding(
                        padding: const .symmetric(vertical: 16.0),
                        child: BlocBuilder<KycEmailVerificationCubit, KycEmailVerificationState>(
                          builder: (context, state) {
                            final isLoading = state is KycEmailVerificationLoading;
                            final isBitbox = context
                                    .read<HomeBloc>()
                                    .state
                                    .openWallet
                                    ?.currentAccount
                                    .primaryAddress is BitboxCredentials;
                            return Column(
                              spacing: 12,
                              children: [
                                AppFilledButton(
                                  state: isLoading ? .loading : .idle,
                                  onPressed: () => context
                                      .read<KycEmailVerificationCubit>()
                                      .checkEmailVerification(),
                                  label: S.of(context).registerEmailVerificationButton,
                                ),
                                if (isLoading && isBitbox)
                                  Text(
                                    S.of(context).registerEmailVerificationBitboxSignHint,
                                    textAlign: .center,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: RealUnitColors.neutral500,
                                    ),
                                  ),
                              ],
                            );
                          },
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
