import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/verify_seed/cubit/verify_seed_cubit.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

class VerifySeedButton extends StatelessWidget {
  const VerifySeedButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .symmetric(vertical: 20),
      child: _buildButton(context),
    );
  }

  Widget _buildButton(BuildContext context) {
    final state = context.watch<VerifySeedCubit>().state;

    if (state.hasError) {
      return AppFilledButton(
        label: S.of(context).verifySeedInvalid,
        state: .error,
      );
    }
    if (state.isVerified) {
      return AppFilledButton(
        icon: Icons.check,
        label: S.of(context).verifySeedSuccessful,
        state: .success,
      );
    }
    if (state.isVerifying) {
      return AppFilledButton(
        label: S.of(context).confirm,
        state: .loading,
      );
    }
    if (state.commitFailed) {
      // The words matched but persisting threw. Offer a tappable retry —
      // the `.idle` state keeps `onPressed` wired (the `.error` variant
      // hard-nulls it). The cubit's re-entrancy guard plus the
      // `commitFailed` reset on retry make a second `verify()` call safe.
      return AppFilledButton(
        onPressed: () => context.read<VerifySeedCubit>().verify(),
        icon: Icons.refresh,
        label: S.of(context).verifySeedCommitFailed,
      );
    }
    return AppFilledButton(
      onPressed: state.canVerify ? () => context.read<VerifySeedCubit>().verify() : null,
      label: S.of(context).confirm,
    );
  }
}
