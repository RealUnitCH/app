import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/registration_date_unavailable_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/registration_rejected_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_status.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/real_unit_user_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/packages/wallet/exceptions/signing_cancelled_exception.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/connect_bitbox_page.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/scrollable_actions_layout.dart';

/// One explanation and one sign action. The approved name comes from the API
/// via [KycSuccess.shareRegisterName]; the page does not collect a form.
class KycUpdateShareRegisterNamePage extends StatefulWidget {
  final RealUnitUserDataDto? userData;
  final String? shareRegisterName;

  const KycUpdateShareRegisterNamePage({
    super.key,
    required this.userData,
    required this.shareRegisterName,
  });

  @override
  State<KycUpdateShareRegisterNamePage> createState() => _KycUpdateShareRegisterNamePageState();
}

class _KycUpdateShareRegisterNamePageState extends State<KycUpdateShareRegisterNamePage> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final userData = widget.userData;
    final shareRegisterName = widget.shareRegisterName;
    if (userData == null || shareRegisterName == null || shareRegisterName.isEmpty) {
      return const _UpdateShareRegisterNameMissingDataPage();
    }
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).shareRegisterNameTitle)),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SafeArea(
          child: ScrollableActionsLayout(
            centerBody: false,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16.0,
              children: [
                const SizedBox(height: 16.0),
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
                state: _submitting ? FilledButtonState.loading : FilledButtonState.idle,
                onPressed: _submitting ? null : () => _submit(userData, shareRegisterName),
                label: S.of(context).shareRegisterNameAction,
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(RealUnitUserDataDto userData, String shareRegisterName) async {
    setState(() => _submitting = true);
    try {
      final response = await getIt<RealUnitRegistrationService>().updateShareRegisterName(
        userData,
        shareRegisterName,
      );
      if (!mounted) return;
      switch (response.status) {
        case RegistrationStatus.completed:
        case RegistrationStatus.alreadyRegistered:
          context.read<KycCubit>().checkKyc();
          return;
        case RegistrationStatus.forwardingFailed:
          final rejection = response.rejectionMessage;
          _showFailure(
            rejection ?? S.of(context).shareRegisterNameFailed,
          );
          setState(() => _submitting = false);
          return;
        case RegistrationStatus.pendingReview:
          _showFailure(S.of(context).shareRegisterNameFailed);
          setState(() => _submitting = false);
          return;
      }
    } on BitboxNotConnectedException {
      if (!mounted) return;
      final result = await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => ConnectBitboxPage(
          onFinish: (wallet) {
            if (!context.mounted) return;
            context.read<HomeBloc>().add(SyncWalletServicesEvent(wallet));
            context.pop(true);
          },
        ),
      );
      if (!mounted) return;
      if (result == true) {
        await _submit(userData, shareRegisterName);
        return;
      }
      setState(() => _submitting = false);
    } on SigningCancelledException {
      if (!mounted) return;
      _showFailure(S.of(context).signingCancelled);
      setState(() => _submitting = false);
    } on RegistrationDateUnavailableException {
      if (!mounted) return;
      _showFailure(S.of(context).registrationDateUnavailable);
      setState(() => _submitting = false);
    } on RegistrationRejectedException catch (e) {
      if (!mounted) return;
      _showFailure(e.message);
      setState(() => _submitting = false);
    } catch (_) {
      if (!mounted) return;
      _showFailure(S.of(context).shareRegisterNameFailed);
      setState(() => _submitting = false);
    }
  }

  void _showFailure(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: RealUnitColors.status.red600,
      ),
    );
  }
}

/// Defensive surface when the cubit routed here without the payload the sign
/// call needs. The user retries the routing decision instead of posting blind.
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
