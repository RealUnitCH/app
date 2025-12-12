import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/restore_wallet/bloc/restore_wallet_cubit.dart';
import 'package:realunit_wallet/screens/restore_wallet/cubit/validate_seed_cubit.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/styles.dart';

class RestoreWalletButton extends StatelessWidget {
  const RestoreWalletButton({
    super.key,
    required List<TextEditingController> controllers,
  }) : _controllers = controllers;

  final List<TextEditingController> _controllers;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ValidateSeedCubit, ValidateSeedState>(
      listener: (context, seedState) {
        if (seedState == ValidateSeedState.valid) {
          context.read<RestoreWalletCubit>().restoreWallet(_seed);
        }
      },
      builder: (context, seedState) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: SizedBox(
            width: double.infinity,
            child: _buildButton(context, seedState),
          ),
        );
      },
    );
  }

  Widget _buildButton(BuildContext context, ValidateSeedState seedState) {
    if (seedState == ValidateSeedState.valid) {
      return _buildRestoreWalletStateButton(context);
    }

    if (seedState == ValidateSeedState.invalid) {
      return _buildStaticButton(
        background: RealUnitColors.status.red600,
        child: const Text('Wiederherstellungs-Wörter ungültig'),
      );
    }

    if (seedState == ValidateSeedState.complete) {
      return _buildActionButton(
        context,
        onPressed: () => context.read<ValidateSeedCubit>().validateSeed(_seed),
        enabled: true,
      );
    }

    return _buildActionButton(
      context,
      onPressed: null,
      enabled: false,
    );
  }

  Widget _buildRestoreWalletStateButton(BuildContext context) {
    return BlocBuilder<RestoreWalletCubit, RestoreWalletState>(
      builder: (context, state) {
        if (state.isLoading) {
          return FilledButton.icon(
            onPressed: null,
            style: kFullwidthBlueButtonStyle.copyWith(
              backgroundColor: WidgetStateProperty.all(
                RealUnitColors.realUnitBlue.withValues(alpha: 0.5),
              ),
              foregroundColor: WidgetStateProperty.all(
                RealUnitColors.basic.white.withValues(alpha: 0.5),
              ),
            ),
            label: Text(S.of(context).next),
            icon: SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: RealUnitColors.basic.white.withValues(alpha: 0.5),
              ),
            ),
          );
        }

        return FilledButton.icon(
          onPressed: null,
          style: kFullwidthBlueButtonStyle.copyWith(
            backgroundColor: WidgetStateProperty.all(RealUnitColors.green),
            foregroundColor: WidgetStateProperty.all(RealUnitColors.basic.white),
          ),
          label: const Text('Wallet wiederhergestellt'),
          icon: const Icon(Icons.check),
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required VoidCallback? onPressed,
    required bool enabled,
  }) {
    return FilledButton(
      onPressed: enabled ? onPressed : null,
      style: kFullwidthBlueButtonStyle.copyWith(
        backgroundColor: _resolveColor(
          enabled,
          RealUnitColors.realUnitBlue,
          RealUnitColors.neutral200,
        ),
        foregroundColor: _resolveColor(
          enabled,
          RealUnitColors.basic.white,
          RealUnitColors.neutral400,
        ),
      ),
      child: Text(
        S.of(context).next,
      ),
    );
  }

  Widget _buildStaticButton({
    required Widget child,
    required Color background,
  }) {
    return FilledButton(
      onPressed: null,
      style: kFullwidthBlueButtonStyle.copyWith(
        backgroundColor: WidgetStateProperty.all(background),
        foregroundColor: WidgetStateProperty.all(RealUnitColors.basic.white),
      ),
      child: child,
    );
  }

  WidgetStateProperty<Color?> _resolveColor(bool enabled, Color active, Color disabled) {
    return WidgetStateProperty.resolveWith<Color?>(
      (states) => enabled && !states.contains(WidgetState.disabled) ? active : disabled,
    );
  }

  String get _seed => _controllers.map((c) => c.text.trim()).join(' ');
}
