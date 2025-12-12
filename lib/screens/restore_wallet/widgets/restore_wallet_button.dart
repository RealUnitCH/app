import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/restore_wallet/cubit/restore_wallet/restore_wallet_cubit.dart';
import 'package:realunit_wallet/screens/restore_wallet/cubit/validate_seed/validate_seed_cubit.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/mnemonic_input_field_controller.dart';

class RestoreWalletButton extends StatelessWidget {
  const RestoreWalletButton({
    super.key,
    required List<MnemonicInputFieldController> controllers,
  }) : _controllers = controllers;

  final List<MnemonicInputFieldController> _controllers;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: SizedBox(
        width: double.infinity,
        child: _buildButton(context),
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    final seedState = context.watch<ValidateSeedCubit>().state;
    final restoreWalletState = context.watch<RestoreWalletCubit>().state;

    switch (seedState) {
      case ValidateSeedState.valid:
        if (restoreWalletState.wallet != null) {
          return FilledButton.icon(
            onPressed: null,
            icon: const Icon(Icons.check),
            style: ButtonStyle(
              backgroundColor: WidgetStateColor.resolveWith((states) => RealUnitColors.green),
              foregroundColor: WidgetStateColor.resolveWith((states) => RealUnitColors.basic.white),
            ),
            label: Text(S.of(context).restore_wallet_successful),
          );
        }
        return FilledButton.icon(
          onPressed: null,
          icon: SizedBox(
            height: 14,
            width: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          style: ButtonStyle(
            backgroundColor: WidgetStateColor.resolveWith(
                (states) => RealUnitColors.realUnitBlue.withValues(alpha: 0.5)),
            foregroundColor: WidgetStateColor.resolveWith(
                (states) => RealUnitColors.basic.white.withValues(alpha: 0.5)),
          ),
          label: Text(S.of(context).next),
        );
      case (ValidateSeedState.invalid):
        return FilledButton(
          onPressed: null,
          style: ButtonStyle(
            backgroundColor: WidgetStateColor.resolveWith((states) => RealUnitColors.status.red600),
            foregroundColor: WidgetStateColor.resolveWith((states) => RealUnitColors.basic.white),
          ),
          child: Text(S.of(context).recovery_words_invalid),
        );
      default:
        return FilledButton(
          onPressed: seedState == ValidateSeedState.complete
              ? () => context.read<ValidateSeedCubit>().validateSeed(_controllers.seed)
              : null,
          child: Text(
            S.of(context).next,
          ),
        );
    }
  }
}
