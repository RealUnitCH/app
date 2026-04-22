import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/restore_wallet/cubit/restore_wallet/restore_wallet_cubit.dart';
import 'package:realunit_wallet/screens/restore_wallet/cubit/validate_seed/validate_seed_cubit.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/mnemonic_field.dart';

class RestoreWalletButton extends StatelessWidget {
  const RestoreWalletButton({
    super.key,
    required List<MnemonicInputFieldController> controllers,
  }) : _controllers = controllers;

  final List<MnemonicInputFieldController> _controllers;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .symmetric(vertical: 20),
      child: _buildButton(context),
    );
  }

  Widget _buildButton(BuildContext context) {
    final seedState = context.watch<ValidateSeedCubit>().state;
    final restoreWalletState = context.watch<RestoreWalletCubit>().state;

    switch (seedState) {
      case ValidateSeedState.valid:
        if (restoreWalletState.wallet != null) {
          return AppFilledButton(
            icon: Icons.check,
            label: S.of(context).restoreWalletSuccessful,
            state: .success,
          );
        }
        return AppFilledButton(
          label: S.of(context).next,
          state: .loading,
        );
      case (ValidateSeedState.invalid):
        return AppFilledButton(
          label: S.of(context).recoveryWordsInvalid,
          state: .error,
        );
      default:
        return AppFilledButton(
          label: S.of(context).next,
          onPressed: seedState == ValidateSeedState.complete
              ? () => context.read<ValidateSeedCubit>().validateSeed(_controllers.seed)
              : null,
        );
    }
  }
}
