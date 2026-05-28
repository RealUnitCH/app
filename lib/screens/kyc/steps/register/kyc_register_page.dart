import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/real_unit_user_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/show_bitbox_reconnect_sheet.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/register/cubits/kyc_register_cubit.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

/// Type for the BitBox reconnect-sheet opener. Injectable so widget tests
/// can stub the sheet (the real `showBitboxReconnectSheet` opens
/// `ConnectBitboxPage`, which carries a full chain of DI-resolved hardware
/// services that aren't relevant to the page-level wiring under test).
typedef BitboxReconnectSheet = Future<bool> Function(BuildContext context);

class KycRegisterPage extends StatelessWidget {
  /// Server-supplied user data the parent `KycCubit` already fetched as part
  /// of its routing decision. The backend always populates this for
  /// `NewRegistration`, so `null` is treated as an unexpected state — the page
  /// surfaces a retry button that re-fires the parent cubit's `checkKyc()`.
  final RealUnitUserDataDto? userData;

  /// Optional override for the BitBox reconnect sheet opener. Production
  /// callers leave this `null` and the page wires up
  /// `showBitboxReconnectSheet`; widget tests inject a stub so the page-level
  /// recovery logic can be asserted without standing up the full BitBox
  /// hardware chain.
  final BitboxReconnectSheet? reconnectSheet;

  const KycRegisterPage({super.key, this.userData, this.reconnectSheet});

  @override
  Widget build(BuildContext context) {
    final data = userData;
    if (data == null) {
      return const _RegisterMissingUserDataPage();
    }
    return BlocProvider(
      create: (_) => KycRegisterCubit(
        getIt<RealUnitRegistrationService>(),
        data,
      ),
      child: KycRegisterView(reconnectSheet: reconnectSheet),
    );
  }
}

class KycRegisterView extends StatelessWidget {
  const KycRegisterView({super.key, this.reconnectSheet});

  /// See `KycRegisterPage.reconnectSheet`.
  final BitboxReconnectSheet? reconnectSheet;

  @override
  Widget build(BuildContext context) {
    final openReconnectSheet = reconnectSheet ?? showBitboxReconnectSheet;
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).kycRegisterTitle)),
      body: BlocConsumer<KycRegisterCubit, KycRegisterState>(
        listenWhen: (_, current) =>
            current is KycRegisterSuccess ||
            current is KycRegisterFailure ||
            current is KycRegisterBitboxRequired,
        listener: (context, state) async {
          if (state is KycRegisterSuccess) {
            // Re-fetch routing state from the API. The wallet is now in the
            // Aktionariat share register, so `getRegistrationInfo` will return
            // `AlreadyRegistered` and `_runCheckKyc` will dispatch the next
            // KYC step.
            context.read<KycCubit>().checkKyc();
          }
          if (state is KycRegisterFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(S.of(context).registrationFailed(state.message)),
                backgroundColor: RealUnitColors.status.red600,
              ),
            );
          }
          if (state is KycRegisterBitboxRequired) {
            // Mirror of the sell / settings-edit recovery: re-open the
            // pairing sheet, and on a successful re-pair retry the
            // registration in place. If the user dismisses the sheet without
            // re-pairing, revert to Ready so the page is interactive again
            // — the user can re-tap submit once the device is back.
            final cubit = context.read<KycRegisterCubit>();
            final reconnected = await openReconnectSheet(context);
            if (reconnected) {
              await cubit.submit(state.userData);
            } else {
              cubit.revertToReady(state.userData);
            }
          }
        },
        builder: (context, state) => switch (state) {
          KycRegisterReady(:final userData) => _RegisterBody(
            userData: userData,
            isSubmitting: false,
          ),
          KycRegisterSubmitting(:final userData) => _RegisterBody(
            userData: userData,
            isSubmitting: true,
          ),
          // Render the disabled body underneath the reconnect sheet so the
          // user keeps their place — the listener above drives the recovery.
          KycRegisterBitboxRequired(:final userData) => _RegisterBody(
            userData: userData,
            isSubmitting: true,
          ),
          KycRegisterProfileIncomplete() => const _RegisterProfileIncompleteBody(),
          // Success: the Bloc listener kicks off `checkKyc` which transitions
          // the parent KycCubit, so this branch is a transient frame. Render
          // the spinner to avoid a flash of the body.
          KycRegisterSuccess() => const Center(child: CupertinoActivityIndicator()),
          KycRegisterState() => const Center(child: CupertinoActivityIndicator()),
        },
      ),
    );
  }
}

class _RegisterBody extends StatelessWidget {
  const _RegisterBody({required this.userData, required this.isSubmitting});

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
            const Icon(
              Icons.info_outline,
              size: 48,
              color: RealUnitColors.neutral500,
            ),
            Text(
              S.of(context).kycRegisterDescription,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            _RegisterInfoRow(
              label: S.of(context).walletAddress,
              value: walletAddress,
            ),
            const Spacer(),
            AppFilledButton(
              state: isSubmitting ? FilledButtonState.loading : FilledButtonState.idle,
              onPressed: isSubmitting
                  ? null
                  : () => context.read<KycRegisterCubit>().submit(userData),
              label: S.of(context).kycRegisterSubmit,
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}

class _RegisterInfoRow extends StatelessWidget {
  const _RegisterInfoRow({required this.label, required this.value});

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

/// Terminal state surface: the prefill payload was missing required fields,
/// so the user can't proceed with a one-tap registration. The page directs
/// them to fix their profile via a separate flow.
class _RegisterProfileIncompleteBody extends StatelessWidget {
  const _RegisterProfileIncompleteBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SafeArea(
        child: Column(
          spacing: 16.0,
          children: [
            const Spacer(),
            const Icon(
              Icons.info_outline,
              size: 48,
              color: RealUnitColors.neutral500,
            ),
            Text(
              S.of(context).kycRegisterProfileIncompleteMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

/// Defensive surface when the parent `KycCubit` routed to `registration` but
/// did not supply userData. In practice the backend always pairs
/// `NewRegistration` with userData, so this is a hard edge case — the user
/// retries the routing decision rather than re-fetching the wallet status
/// from the page itself.
class _RegisterMissingUserDataPage extends StatelessWidget {
  const _RegisterMissingUserDataPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).kycRegisterTitle)),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SafeArea(
          child: Column(
            spacing: 16.0,
            children: [
              const Spacer(),
              Text(
                S.of(context).kycFailure,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              AppFilledButton(
                onPressed: () => context.read<KycCubit>().checkKyc(),
                label: S.of(context).refresh,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
