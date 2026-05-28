import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/real_unit_user_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_wallet_service.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/link_wallet/cubits/kyc_link_wallet_cubit.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

class KycLinkWalletPage extends StatelessWidget {
  const KycLinkWalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => KycLinkWalletCubit(
        getIt<RealUnitWalletService>(),
        getIt<RealUnitRegistrationService>(),
      )..loadUserData(),
      child: const KycLinkWalletView(),
    );
  }
}

class KycLinkWalletView extends StatelessWidget {
  const KycLinkWalletView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).kycLinkWalletTitle)),
      body: BlocConsumer<KycLinkWalletCubit, KycLinkWalletState>(
        listenWhen: (_, current) =>
            current is KycLinkWalletSuccess || current is KycLinkWalletFailure,
        listener: (context, state) {
          if (state is KycLinkWalletSuccess) {
            // Re-fetch routing state from the API. The wallet is now in the
            // Aktionariat share register, so `getWalletStatus` will return
            // `AlreadyRegistered` and `_runCheckKyc` will dispatch the next
            // KYC step.
            context.read<KycCubit>().checkKyc();
          }
          if (state is KycLinkWalletFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(S.of(context).registrationFailed(state.message)),
                backgroundColor: RealUnitColors.status.red600,
              ),
            );
          }
        },
        builder: (context, state) => switch (state) {
          KycLinkWalletInitial() ||
          KycLinkWalletLoading() => const Center(child: CupertinoActivityIndicator()),
          KycLinkWalletFailure(:final message) => _LinkWalletErrorBody(message: message),
          KycLinkWalletReady(:final userData) => _LinkWalletBody(
            userData: userData,
            isSubmitting: false,
          ),
          KycLinkWalletSubmitting(:final userData) => _LinkWalletBody(
            userData: userData,
            isSubmitting: true,
          ),
          // Success: the Bloc listener kicks off `checkKyc` which transitions
          // the parent KycCubit, so this branch is a transient frame. Render
          // the spinner to avoid a flash of the form.
          KycLinkWalletSuccess() => const Center(child: CupertinoActivityIndicator()),
          KycLinkWalletState() => const Center(child: CupertinoActivityIndicator()),
        },
      ),
    );
  }
}

class _LinkWalletBody extends StatelessWidget {
  const _LinkWalletBody({required this.userData, required this.isSubmitting});

  final RealUnitUserDataDto userData;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final walletAddress = getIt<AppStore>().wallet.primaryAccount.primaryAddress.address.hexEip55;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SafeArea(
        child: Column(
          spacing: 16.0,
          children: [
            const SizedBox(height: 16.0),
            Text(
              S.of(context).kycLinkWalletDescription,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            _LinkWalletInfoRow(
              label: S.of(context).name,
              value: userData.name,
            ),
            _LinkWalletInfoRow(
              label: S.of(context).walletAddress,
              value: walletAddress,
            ),
            const Spacer(),
            AppFilledButton(
              state: isSubmitting ? FilledButtonState.loading : FilledButtonState.idle,
              onPressed: isSubmitting
                  ? null
                  : () => context.read<KycLinkWalletCubit>().submit(userData),
              label: S.of(context).kycLinkWalletSubmit,
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}

class _LinkWalletInfoRow extends StatelessWidget {
  const _LinkWalletInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4.0,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: RealUnitColors.neutral500,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _LinkWalletErrorBody extends StatelessWidget {
  const _LinkWalletErrorBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SafeArea(
        child: Column(
          spacing: 16.0,
          children: [
            const Spacer(),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            AppFilledButton(
              onPressed: () => context.read<KycLinkWalletCubit>().loadUserData(),
              label: S.of(context).refresh,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
