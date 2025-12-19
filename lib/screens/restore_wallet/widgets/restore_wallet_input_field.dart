import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/screens/restore_wallet/cubit/restore_wallet/restore_wallet_cubit.dart';
import 'package:realunit_wallet/screens/restore_wallet/cubit/validate_seed/validate_seed_cubit.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/mnemonic_field.dart';
import 'package:realunit_wallet/widgets/mnemonic_input_field_controller.dart';

class RestoreWalletInputField extends StatelessWidget {
  const RestoreWalletInputField({
    super.key,
    required List<MnemonicInputFieldController> controllers,
    required List<FocusNode> focusNodes,
  })  : _controllers = controllers,
        _focusNodes = focusNodes;

  final List<MnemonicInputFieldController> _controllers;
  final List<FocusNode> _focusNodes;

  @override
  Widget build(BuildContext context) {
    final seedState = context.watch<ValidateSeedCubit>().state;
    final restoreWalletState = context.watch<RestoreWalletCubit>().state;

    return MnemonicInputField(
      controllers: _controllers,
      focusNodes: _focusNodes,
      borderColor: seedState == ValidateSeedState.valid
          ? restoreWalletState.isLoading
              ? RealUnitColors.okker
              : RealUnitColors.green
          : seedState == ValidateSeedState.invalid
              ? RealUnitColors.status.red600
              : RealUnitColors.okker,
      onChanged: () => context.read<ValidateSeedCubit>().checkSeedLength(_controllers.seed),
    );
  }
}
