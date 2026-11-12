import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/real_unit_user_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/show_bitbox_reconnect_sheet.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/update_share_register_name/cubits/kyc_update_share_register_name_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/update_share_register_name/cubits/kyc_update_share_register_name_state.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/scrollable_actions_layout.dart';

/// One explanation, the approved name, and one sign action. Not a form.
class KycUpdateShareRegisterNamePage extends StatelessWidget {
  final RealUnitUserDataDto? userData;
  final String? shareRegisterName;

  const KycUpdateShareRegisterNamePage({
    super.key,
    required this.userData,
    required this.shareRegisterName,
  });

  @override
  Widget build(BuildContext context) {
    final data = userData;
    final name = shareRegisterName;
    if (data == null || name == null || name.isEmpty) {
      return const _UpdateShareRegisterNameMissingDataPage();
    }
    return BlocProvider(
      key: ValueKey((data, name)),
      create: (_) => KycUpdateShareRegisterNameCubit(
        getIt<RealUnitRegistrationService>(),
        data,
        name,
      ),
      child: KycUpdateShareRegisterNameView(shareRegisterName: name),
    );
  }
}

class KycUpdateShareRegisterNameView extends StatelessWidget {
  final String shareRegisterName;

  const KycUpdateShareRegisterNameView({super.key, required this.shareRegisterName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).shareRegisterNameTitle)),
      body: BlocConsumer<KycUpdateShareRegisterNameCubit, KycUpdateShareRegisterNameState>(
        listenWhen: (_, current) =>
            current is KycUpdateShareRegisterNameSuccess ||
            current is KycUpdateShareRegisterNameFailure ||
            current is KycUpdateShareRegisterNameBitboxRequired,
        listener: (context, state) async {
          if (state is KycUpdateShareRegisterNameSuccess) {
            context.read<KycCubit>().checkKyc();
          }
          if (state is KycUpdateShareRegisterNameFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: RealUnitColors.status.red600,
              ),
            );
          }
          if (state is KycUpdateShareRegisterNameBitboxRequired) {
            // Disconnected BitBox is not a rejection. Open the shared connect
            // sheet over this page and sign again once the device is linked.
            final cubit = context.read<KycUpdateShareRegisterNameCubit>();
            final result = await showBitboxReconnectSheet(context);
            if (result == true && context.mounted && !cubit.isClosed) {
              await cubit.retrySubmit(
                shareRegisterNameFailed: S.of(context).shareRegisterNameFailed,
                shareRegisterNameSendFailed: S.of(context).shareRegisterNameSendFailed,
                registrationDateUnavailable: S.of(context).registrationDateUnavailable,
                signingCancelled: S.of(context).signingCancelled,
              );
            }
          }
        },
        builder: (context, state) {
          if (state is KycUpdateShareRegisterNameSuccess) {
            return const Center(child: CupertinoActivityIndicator());
          }
          return _UpdateShareRegisterNameBody(
            shareRegisterName: shareRegisterName,
            isSubmitting: state is KycUpdateShareRegisterNameSubmitting,
          );
        },
      ),
    );
  }
}

class _UpdateShareRegisterNameBody extends StatelessWidget {
  const _UpdateShareRegisterNameBody({
    required this.shareRegisterName,
    required this.isSubmitting,
  });

  final String shareRegisterName;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SafeArea(
        child: ScrollableActionsLayout(
          centerBody: false,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16.0,
            children: [
              Text(
                S.of(context).shareRegisterNameBody,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              Text(
                shareRegisterName,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            AppFilledButton(
              state: isSubmitting ? FilledButtonState.loading : FilledButtonState.idle,
              onPressed: isSubmitting
                  ? null
                  : () => context.read<KycUpdateShareRegisterNameCubit>().submit(
                      shareRegisterNameFailed: S.of(context).shareRegisterNameFailed,
                      shareRegisterNameSendFailed: S.of(context).shareRegisterNameSendFailed,
                      registrationDateUnavailable: S.of(context).registrationDateUnavailable,
                      signingCancelled: S.of(context).signingCancelled,
                    ),
              label: S.of(context).shareRegisterNameAction,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when the route arrived without the payload the sign call needs.
/// The user retries the routing decision instead of posting blind.
class _UpdateShareRegisterNameMissingDataPage extends StatelessWidget {
  const _UpdateShareRegisterNameMissingDataPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).shareRegisterNameTitle)),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SafeArea(
          child: ScrollableActionsLayout(
            centerBody: true,
            body: Text(
              S.of(context).kycFailure,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            actions: [
              AppFilledButton(
                onPressed: () => context.read<KycCubit>().checkKyc(),
                label: S.of(context).refresh,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
